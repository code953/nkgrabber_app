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

// file_picker 11.x is written in Kotlin but, under AGP 9, stops applying the
// Kotlin plugin and relies on AGP's built-in Kotlin. The Flutter template turns
// that off (`android.builtInKotlin=false` in gradle.properties), so nothing
// compiles its sources: the build only fails at the very end, when
// GeneratedPluginRegistrant cannot find FilePickerPlugin. Apply the plugin for
// it, as upstream does since 12.0.0. Remove this once file_picker can move to
// 12+, which needs win32 6 and therefore flutter_secure_storage 10.
val builtInKotlin = providers.gradleProperty("android.builtInKotlin").orNull != "false"
subprojects {
    if (name == "file_picker" && !builtInKotlin) {
        plugins.withId("com.android.library") {
            pluginManager.apply("org.jetbrains.kotlin.android")
        }
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            // Must match the plugin's Java target, or KGP refuses to build.
            compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
