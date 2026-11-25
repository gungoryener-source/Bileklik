# Yayın derlemesinde R8 kod küçültme açık. JNI ve yansımayla çağrılan sınıflar
# silinirse uygulama açılışta çöker; eklentilerin README'lerinde istenen kurallar.

# sqflite_sqlcipher: SQLCipher yerel kitaplığı bu sınıfları JNI ile arar.
-keep class net.sqlcipher.** { *; }
-keep class net.zetetic.** { *; }
-dontwarn net.sqlcipher.**
-dontwarn net.zetetic.**

# flutter_blue_plus
-keep class com.lib.flutter_blue_plus.* { *; }

# health (Health Connect)
-keep class androidx.health.** { *; }
-dontwarn androidx.health.**

# flutter_secure_storage (Tink)
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**
