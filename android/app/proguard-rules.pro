# TensorFlow Lite
-keep class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**

# TensorFlow Lite GPU
-keep class org.tensorflow.lite.gpu.** { *; }
-dontwarn org.tensorflow.lite.gpu.**

# Specifically keep GpuDelegateFactory$Options
-keep class org.tensorflow.lite.gpu.GpuDelegateFactory$Options { *; }