# Naver Login SDK models and Retrofit interfaces are accessed reflectively.
-keep public class com.nhn.android.naverlogin.** {
    public protected *;
}
-keep public class com.navercorp.nid.** {
    public *;
}
-keep class com.navercorp.nid.profile.domain.vo.NidProfileDetail {
    <fields>;
}

-if interface * { @retrofit2.http.* <methods>; }
-keep,allowobfuscation interface <1>
-keep,allowobfuscation,allowshrinking class kotlin.coroutines.Continuation
-if interface * { @retrofit2.http.* public *** *(...); }
-keep,allowoptimization,allowshrinking,allowobfuscation class <3>
-keep,allowobfuscation,allowshrinking class retrofit2.Response
