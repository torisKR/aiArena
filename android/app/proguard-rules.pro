# WorkManager initializes Room before Flutter's main(). Room 2.2.5 creates
# WorkDatabase_Impl reflectively; its class-only consumer rule does not retain
# the public no-argument constructor in R8 full mode.
-keep class androidx.work.impl.WorkDatabase_Impl {
    public <init>();
}
