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

// --- LE FIX MAGIQUE EST DE RETOUR (POUR telephony) ---
// Ce bloc force l'ajout d'un namespace aux vieilles librairies
subprojects {
    afterEvaluate {
        val android = extensions.findByName("android")
        if (android != null) {
            try {
                // On utilise la réflexion pour accéder à getNamespace/setNamespace
                // cela évite les erreurs de compilation si l'API change
                val getNamespace = android.javaClass.getMethod("getNamespace")
                val currentNamespace = getNamespace.invoke(android)

                if (currentNamespace == null) {
                    val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)

                    var newNamespace = group.toString()
                    // Génération d'un nom de package unique si manquant
                    if (newNamespace == "null" || newNamespace.isEmpty()) {
                        newNamespace = "com.example.${name.replace(Regex("[^a-zA-Z0-9_]"), "_")}"
                    }

                    setNamespace.invoke(android, newNamespace)
                    println("✅ FIX: Namespace généré pour le module '$name' -> '$newNamespace'")
                }
            } catch (e: Exception) {
                // On ignore silencieusement les erreurs
            }
        }
    }
}
// -----------------------------------------------------

// IMPORTANT : Cette ligne doit être APRÈS le fix ci-dessus
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}