allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    if (project.name == "blue_thermal_printer") {
        fun fixNamespace() {
            try {
                val android = project.extensions.findByName("android")
                if (android != null) {
                    val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                    setNamespace.invoke(android, "id.kakzaki.blue_thermal_printer")
                    println("Injected namespace for blue_thermal_printer")
                }
            } catch (e: Exception) {
                println("Failed to inject namespace for blue_thermal_printer: ${e.message}")
            }
        }

        if (project.state.executed) {
            fixNamespace()
        } else {
            project.afterEvaluate {
                fixNamespace()
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
