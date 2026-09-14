allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

// Older Flutter plugins (e.g. blue_thermal_printer 1.2.3) declare their package only in
// AndroidManifest.xml, which AGP 8+ rejects with "Namespace not specified". Backfill the
// namespace from the manifest so those modules keep configuring.
val backfillNamespace: (Project) -> Unit = { project ->
    val androidExtension = project.extensions.findByName("android")
    val getNamespace =
        androidExtension?.javaClass?.methods?.firstOrNull {
            it.name == "getNamespace" && it.parameterCount == 0
        }
    val setNamespace =
        androidExtension?.javaClass?.methods?.firstOrNull {
            it.name == "setNamespace" && it.parameterCount == 1
        }

    if (getNamespace != null &&
        setNamespace != null &&
        (getNamespace.invoke(androidExtension) as String?).isNullOrBlank()
    ) {
        val manifest = project.file("src/main/AndroidManifest.xml")
        val namespace =
            manifest
                .takeIf { it.exists() }
                ?.let { Regex("""package\s*=\s*"([^"]+)"""").find(it.readText())?.groupValues?.get(1) }
                ?: project.group.toString()

        if (namespace.isNotBlank()) {
            setNamespace.invoke(androidExtension, namespace)
            project.logger.lifecycle("Applied missing namespace '$namespace' to :${project.name}")
        }
    }
}

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // Must be registered before the :app evaluation forced below, otherwise Gradle refuses
    // to add an afterEvaluate hook to an already evaluated project.
    if (project.state.executed) {
        backfillNamespace(project)
    } else {
        project.afterEvaluate { backfillNamespace(this) }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
