import org.gradle.api.JavaVersion
import org.gradle.api.Project

allprojects {
    repositories {
        google()
        mavenCentral()
    }

    afterEvaluate {
        // Configure Java Toolchain for all projects with Java capabilities
        plugins.withId("java-base") {
            extensions.configure<org.gradle.api.plugins.JavaPluginExtension> {
                toolchain {
                    languageVersion.set(org.gradle.jvm.toolchain.JavaLanguageVersion.of(17))
                }
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }

        // Configure compileOptions for Android projects (app or library)
        extensions.findByType(com.android.build.gradle.BaseExtension::class.java)?.let { androidExt ->
            androidExt.compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }
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

// Set Kotlin JVM target for all subprojects
subprojects {
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        kotlinOptions {
            jvmTarget = "17"
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
