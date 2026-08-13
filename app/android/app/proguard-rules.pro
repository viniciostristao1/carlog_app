# ML Kit Text Recognition — o CarLog só usa o script LATIN. O plugin referencia
# os reconhecedores dos outros idiomas (chinês, devanágari, japonês, coreano),
# que NÃO incluímos no app. Sem estas regras o R8 (minify) falha com
# "Missing class ...". Ignoramos essas classes opcionais com segurança.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
