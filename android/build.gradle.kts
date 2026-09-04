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

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    val project = this
    val configureAndroid: (Project) -> Unit = { p ->
        if (p.hasProperty("android")) {
            val android = p.extensions.getByName("android")
            try {
                val method = android.javaClass.getMethod("compileSdkVersion", Int::class.javaPrimitiveType ?: Int::class.java)
                method.invoke(android, 36)
            } catch (e: Exception) {
                // Ignore if method not found
            }
        }
    }

    if (project.state.executed) {
        configureAndroid(project)
    } else {
        project.afterEvaluate {
            configureAndroid(project)
        }
    }
}
