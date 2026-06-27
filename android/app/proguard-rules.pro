# kotlinx.serialization keeps generated serializers via @Serializable; the
# plugin emits the metadata, but R8 needs these rules to retain them.
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.**

-keepclassmembers class **$$serializer { *; }
-keepclasseswithmembers class com.aprecis.** {
    kotlinx.serialization.KSerializer serializer(...);
}
-keep,includedescriptorclasses class com.aprecis.**$$serializer { *; }
-keep @kotlinx.serialization.Serializable class com.aprecis.** { *; }

# Retrofit / OkHttp
-keepattributes Signature, Exceptions
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn retrofit2.**
