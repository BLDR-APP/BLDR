# Preservar o Firebase e Google Play Services
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Preservar o Stripe (se estiver usando o SDK oficial)
-keep class com.stripe.** { *; }

# Preservar classes do Supabase/PostgREST/Serialization
-keep class io.github.jan.supabase.** { *; }
-keep class kotlinx.serialization.** { *; }

# Evitar erros comuns de ofuscação
-keepattributes Signature, *Annotation*, InnerClasses
-dontwarn okio.**
-dontwarn javax.annotation.**

# Ignorar avisos de classes ausentes do Stripe (como Push Provisioning)
-dontwarn com.stripe.android.pushProvisioning.**
-dontwarn com.reactnativestripesdk.**