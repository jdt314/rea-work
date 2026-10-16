; ModuleID = 'C:\Users\jdt314\Desktop\rea-work\capwords-analysis\evidence\ipa\capture-flow\shader-00.bc'
source_filename = "Ripple"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-windows-msvc19.42.34435"

%"struct.SwiftUI::Layer" = type { %"struct.metal::texture2d", [5 x <2 x float>] }
%"struct.metal::texture2d" = type { ptr addrspace(1) }

@__air_sampler_state = internal addrspace(2) constant i64 -9188470239253755319, align 8
@llvm.compiler.used = appending global [16 x ptr] [ptr @_ZN5metal22_stitching_traits_implIDv2_fE13load_argumentEPv, ptr @_ZN5metal22_stitching_traits_implIDv2_fE16copy_from_bufferEPvPU11MTLconstantKv, ptr @_ZN5metal22_stitching_traits_implIDv2_fE18store_return_valueEPvS1_, ptr @_ZN5metal22_stitching_traits_implIDv2_fE7destroyEPv, ptr @_ZN5metal22_stitching_traits_implIDv4_DhE13load_argumentEPv, ptr @_ZN5metal22_stitching_traits_implIDv4_DhE16copy_from_bufferEPvPU11MTLconstantKv, ptr @_ZN5metal22_stitching_traits_implIDv4_DhE18store_return_valueEPvS1_, ptr @_ZN5metal22_stitching_traits_implIDv4_DhE7destroyEPv, ptr @_ZN5metal22_stitching_traits_implIN7SwiftUI5LayerEE13load_argumentEPv, ptr @_ZN5metal22_stitching_traits_implIN7SwiftUI5LayerEE16copy_from_bufferEPvPU11MTLconstantKv, ptr @_ZN5metal22_stitching_traits_implIN7SwiftUI5LayerEE18store_return_valueEPvS2_, ptr @_ZN5metal22_stitching_traits_implIN7SwiftUI5LayerEE7destroyEPv, ptr @_ZN5metal22_stitching_traits_implIfE13load_argumentEPv, ptr @_ZN5metal22_stitching_traits_implIfE16copy_from_bufferEPvPU11MTLconstantKv, ptr @_ZN5metal22_stitching_traits_implIfE18store_return_valueEPvf, ptr @_ZN5metal22_stitching_traits_implIfE7destroyEPv], section "llvm.metadata"

; Function Attrs: alwaysinline mustprogress nounwind
define internal <2 x float> @_ZN5metal22_stitching_traits_implIDv2_fE13load_argumentEPv(ptr noundef %0) #0 align 2 {
  %2 = bitcast ptr %0 to ptr
  %3 = load <2 x float>, ptr %2, align 8, !tbaa !52
  ret <2 x float> %3
}

; Function Attrs: alwaysinline mustprogress nounwind
define internal void @_ZN5metal22_stitching_traits_implIDv2_fE16copy_from_bufferEPvPU11MTLconstantKv(ptr noundef %0, ptr addrspace(2) noundef %1) #1 align 2 {
  %3 = bitcast ptr %0 to ptr
  %4 = bitcast ptr addrspace(2) %1 to ptr addrspace(2)
  %5 = load <2 x float>, ptr addrspace(2) %4, align 8, !tbaa !52
  store <2 x float> %5, ptr %3, align 8, !tbaa !52
  ret void
}

; Function Attrs: alwaysinline mustprogress nounwind
define internal void @_ZN5metal22_stitching_traits_implIDv2_fE18store_return_valueEPvS1_(ptr noundef %0, <2 x float> noundef %1) #0 align 2 {
  %3 = bitcast ptr %0 to ptr
  store <2 x float> %1, ptr %3, align 8, !tbaa !52
  ret void
}

; Function Attrs: alwaysinline mustprogress nounwind
define internal void @_ZN5metal22_stitching_traits_implIDv2_fE7destroyEPv(ptr noundef %0) #1 align 2 {
  ret void
}

; Function Attrs: alwaysinline mustprogress nounwind
define internal <4 x half> @_ZN5metal22_stitching_traits_implIDv4_DhE13load_argumentEPv(ptr noundef %0) #0 align 2 {
  %2 = bitcast ptr %0 to ptr
  %3 = load <4 x half>, ptr %2, align 8, !tbaa !52
  ret <4 x half> %3
}

; Function Attrs: alwaysinline mustprogress nounwind
define internal void @_ZN5metal22_stitching_traits_implIDv4_DhE16copy_from_bufferEPvPU11MTLconstantKv(ptr noundef %0, ptr addrspace(2) noundef %1) #1 align 2 {
  %3 = bitcast ptr %0 to ptr
  %4 = bitcast ptr addrspace(2) %1 to ptr addrspace(2)
  %5 = load <4 x half>, ptr addrspace(2) %4, align 8, !tbaa !52
  store <4 x half> %5, ptr %3, align 8, !tbaa !52
  ret void
}

; Function Attrs: alwaysinline mustprogress nounwind
define internal void @_ZN5metal22_stitching_traits_implIDv4_DhE18store_return_valueEPvS1_(ptr noundef %0, <4 x half> noundef %1) #0 align 2 {
  %3 = bitcast ptr %0 to ptr
  store <4 x half> %1, ptr %3, align 8, !tbaa !52
  ret void
}

; Function Attrs: alwaysinline mustprogress nounwind
define internal void @_ZN5metal22_stitching_traits_implIDv4_DhE7destroyEPv(ptr noundef %0) #1 align 2 {
  ret void
}

; Function Attrs: alwaysinline mustprogress nounwind
define internal float @_ZN5metal22_stitching_traits_implIfE13load_argumentEPv(ptr noundef %0) #1 align 2 {
  %2 = bitcast ptr %0 to ptr
  %3 = load float, ptr %2, align 4, !tbaa !55
  ret float %3
}

; Function Attrs: alwaysinline mustprogress nounwind
define internal void @_ZN5metal22_stitching_traits_implIfE16copy_from_bufferEPvPU11MTLconstantKv(ptr noundef %0, ptr addrspace(2) noundef %1) #1 align 2 {
  %3 = bitcast ptr %0 to ptr
  %4 = bitcast ptr addrspace(2) %1 to ptr addrspace(2)
  %5 = load float, ptr addrspace(2) %4, align 4, !tbaa !55
  store float %5, ptr %3, align 4, !tbaa !55
  ret void
}

; Function Attrs: alwaysinline mustprogress nounwind
define internal void @_ZN5metal22_stitching_traits_implIfE18store_return_valueEPvf(ptr noundef %0, float noundef %1) #1 align 2 {
  %3 = bitcast ptr %0 to ptr
  store float %1, ptr %3, align 4, !tbaa !55
  ret void
}

; Function Attrs: alwaysinline mustprogress nounwind
define internal void @_ZN5metal22_stitching_traits_implIfE7destroyEPv(ptr noundef %0) #1 align 2 {
  ret void
}

; Function Attrs: alwaysinline mustprogress nounwind
define internal %"struct.SwiftUI::Layer" @_ZN5metal22_stitching_traits_implIN7SwiftUI5LayerEE13load_argumentEPv(ptr noundef %0) #1 align 2 {
  %2 = bitcast ptr %0 to ptr
  %3 = load ptr addrspace(1), ptr %2, align 8
  %4 = getelementptr inbounds i8, ptr %0, i64 8
  %5 = bitcast ptr %4 to ptr
  %6 = load <2 x float>, ptr %5, align 8
  %7 = getelementptr inbounds i8, ptr %0, i64 16
  %8 = bitcast ptr %7 to ptr
  %9 = load <2 x float>, ptr %8, align 8
  %10 = getelementptr inbounds i8, ptr %0, i64 24
  %11 = bitcast ptr %10 to ptr
  %12 = load <2 x float>, ptr %11, align 8
  %13 = getelementptr inbounds i8, ptr %0, i64 32
  %14 = bitcast ptr %13 to ptr
  %15 = load <2 x float>, ptr %14, align 8
  %16 = getelementptr inbounds i8, ptr %0, i64 40
  %17 = bitcast ptr %16 to ptr
  %18 = load <2 x float>, ptr %17, align 8
  %19 = insertvalue %"struct.SwiftUI::Layer" poison, ptr addrspace(1) %3, 0, 0
  %20 = insertvalue %"struct.SwiftUI::Layer" %19, <2 x float> %6, 1, 0
  %21 = insertvalue %"struct.SwiftUI::Layer" %20, <2 x float> %9, 1, 1
  %22 = insertvalue %"struct.SwiftUI::Layer" %21, <2 x float> %12, 1, 2
  %23 = insertvalue %"struct.SwiftUI::Layer" %22, <2 x float> %15, 1, 3
  %24 = insertvalue %"struct.SwiftUI::Layer" %23, <2 x float> %18, 1, 4
  ret %"struct.SwiftUI::Layer" %24
}

; Function Attrs: alwaysinline mustprogress nounwind
define internal void @_ZN5metal22_stitching_traits_implIN7SwiftUI5LayerEE16copy_from_bufferEPvPU11MTLconstantKv(ptr noundef %0, ptr addrspace(2) noundef %1) #1 align 2 {
  tail call void @llvm.memcpy.p0.p2.i64(ptr noundef nonnull align 8 dereferenceable(48) %0, ptr addrspace(2) noundef align 8 dereferenceable(48) %1, i64 48, i1 false)
  ret void
}

; Function Attrs: alwaysinline mustprogress nounwind
define internal void @_ZN5metal22_stitching_traits_implIN7SwiftUI5LayerEE18store_return_valueEPvS2_(ptr noundef %0, %"struct.metal::texture2d" %1, [5 x <2 x float>] %2) #1 align 2 {
  %4 = extractvalue %"struct.metal::texture2d" %1, 0
  %5 = extractvalue [5 x <2 x float>] %2, 0
  %6 = extractvalue [5 x <2 x float>] %2, 1
  %7 = extractvalue [5 x <2 x float>] %2, 2
  %8 = extractvalue [5 x <2 x float>] %2, 3
  %9 = extractvalue [5 x <2 x float>] %2, 4
  %10 = bitcast ptr %0 to ptr
  store ptr addrspace(1) %4, ptr %10, align 8
  %11 = getelementptr inbounds i8, ptr %0, i64 8
  %12 = bitcast ptr %11 to ptr
  store <2 x float> %5, ptr %12, align 8
  %13 = getelementptr inbounds i8, ptr %0, i64 16
  %14 = bitcast ptr %13 to ptr
  store <2 x float> %6, ptr %14, align 8
  %15 = getelementptr inbounds i8, ptr %0, i64 24
  %16 = bitcast ptr %15 to ptr
  store <2 x float> %7, ptr %16, align 8
  %17 = getelementptr inbounds i8, ptr %0, i64 32
  %18 = bitcast ptr %17 to ptr
  store <2 x float> %8, ptr %18, align 8
  %19 = getelementptr inbounds i8, ptr %0, i64 40
  %20 = bitcast ptr %19 to ptr
  store <2 x float> %9, ptr %20, align 8
  ret void
}

; Function Attrs: alwaysinline mustprogress nounwind
define internal void @_ZN5metal22_stitching_traits_implIN7SwiftUI5LayerEE7destroyEPv(ptr noundef %0) #1 align 2 {
  ret void
}

; Function Attrs: convergent mustprogress nofree nounwind willreturn memory(read)
define <4 x half> @Ripple(<2 x float> noundef %0, %"struct.metal::texture2d" %1, [5 x <2 x float>] %2, <2 x float> noundef %3, float noundef %4, float noundef %5, float noundef %6, float noundef %7, float noundef %8) local_unnamed_addr #2 {
  %10 = extractvalue %"struct.metal::texture2d" %1, 0
  %11 = extractvalue [5 x <2 x float>] %2, 0
  %12 = extractvalue [5 x <2 x float>] %2, 1
  %13 = extractvalue [5 x <2 x float>] %2, 2
  %14 = extractvalue [5 x <2 x float>] %2, 3
  %15 = extractvalue [5 x <2 x float>] %2, 4
  %16 = fsub fast <2 x float> %0, %3
  %17 = tail call fast float @air.dot.v2f32(<2 x float> %16, <2 x float> %16) #6
  %18 = tail call fast float @air.fast_sqrt.f32(float %17) #6
  %19 = fdiv fast float %18, %8
  %20 = fsub fast float %4, %19
  %21 = tail call fast float @air.fast_fmax.f32(float 0.000000e+00, float %20) #6
  %22 = fmul fast float %21, %6
  %23 = tail call fast float @air.fast_sin.f32(float %22) #6
  %24 = fmul fast float %23, %5
  %25 = fneg fast float %7
  %26 = fmul fast float %21, %25
  %27 = tail call fast float @air.fast_exp.f32(float %26) #6
  %28 = fmul fast float %24, %27
  %29 = tail call fast float @air.fast_rsqrt.f32(float %17) #6
  %30 = insertelement <2 x float> poison, float %29, i64 0
  %31 = shufflevector <2 x float> %30, <2 x float> poison, <2 x i32> zeroinitializer
  %32 = fmul fast <2 x float> %31, %16
  %33 = insertelement <2 x float> poison, float %28, i64 0
  %34 = shufflevector <2 x float> %33, <2 x float> poison, <2 x i32> zeroinitializer
  %35 = fmul fast <2 x float> %32, %34
  %36 = fadd fast <2 x float> %35, %0
  %37 = shufflevector <2 x float> %36, <2 x float> poison, <2 x i32> zeroinitializer
  %38 = shufflevector <2 x float> %36, <2 x float> undef, <2 x i32> <i32 1, i32 1>
  %39 = tail call fast <2 x float> @air.fma.v2f32(<2 x float> %38, <2 x float> %12, <2 x float> %13) #6
  %40 = tail call fast <2 x float> @air.fma.v2f32(<2 x float> %37, <2 x float> %11, <2 x float> %39) #6
  %41 = tail call fast <2 x float> @air.fast_clamp.v2f32(<2 x float> %40, <2 x float> %14, <2 x float> %15) #6
  %42 = tail call { <4 x half>, i8 } @air.sample_texture_2d.v4f16(ptr addrspace(1) nocapture readonly %10, ptr addrspace(2) nocapture readonly @__air_sampler_state, <2 x float> %41, i1 true, <2 x i32> zeroinitializer, i1 false, float 0.000000e+00, float 0.000000e+00, i32 0) #7
  %43 = extractvalue { <4 x half>, i8 } %42, 0
  %44 = fmul fast float %28, 0x3FD3333340000000
  %45 = extractelement <4 x half> %43, i64 3
  %46 = fpext half %45 to float
  %47 = fmul fast float %44, %46
  %48 = fdiv fast float %47, %5
  %49 = fptrunc float %48 to half
  %50 = insertelement <3 x half> poison, half %49, i64 0
  %51 = shufflevector <3 x half> %50, <3 x half> poison, <3 x i32> zeroinitializer
  %52 = shufflevector <4 x half> %43, <4 x half> poison, <3 x i32> <i32 0, i32 1, i32 2>
  %53 = fadd fast <3 x half> %51, %52
  %54 = shufflevector <3 x half> %53, <3 x half> poison, <4 x i32> <i32 0, i32 1, i32 2, i32 poison>
  %55 = shufflevector <4 x half> %54, <4 x half> %43, <4 x i32> <i32 0, i32 1, i32 2, i32 7>
  ret <4 x half> %55
}

; Function Attrs: convergent mustprogress nofree nounwind willreturn memory(argmem: read)
declare { <4 x half>, i8 } @air.sample_texture_2d.v4f16(ptr addrspace(1) nocapture readonly, ptr addrspace(2) nocapture readonly, <2 x float>, i1, <2 x i32>, i1, float, float, i32) local_unnamed_addr #3

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
declare <2 x float> @air.fast_clamp.v2f32(<2 x float>, <2 x float>, <2 x float>) local_unnamed_addr #4

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
declare <2 x float> @air.fma.v2f32(<2 x float>, <2 x float>, <2 x float>) local_unnamed_addr #4

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
declare float @air.fast_rsqrt.f32(float) local_unnamed_addr #4

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
declare float @air.fast_exp.f32(float) local_unnamed_addr #4

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
declare float @air.fast_sin.f32(float) local_unnamed_addr #4

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
declare float @air.fast_fmax.f32(float, float) local_unnamed_addr #4

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
declare float @air.fast_sqrt.f32(float) local_unnamed_addr #4

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
declare float @air.dot.v2f32(<2 x float>, <2 x float>) local_unnamed_addr #4

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p2.i64(ptr noalias nocapture writeonly, ptr addrspace(2) noalias nocapture readonly, i64, i1 immarg) #5

attributes #0 = { alwaysinline mustprogress nounwind "approx-func-fp-math"="true" "frame-pointer"="all" "min-legal-vector-width"="64" "no-builtins" "no-infs-fp-math"="true" "no-nans-fp-math"="true" "no-signed-zeros-fp-math"="true" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "unsafe-fp-math"="true" }
attributes #1 = { alwaysinline mustprogress nounwind "approx-func-fp-math"="true" "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-infs-fp-math"="true" "no-nans-fp-math"="true" "no-signed-zeros-fp-math"="true" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "unsafe-fp-math"="true" }
attributes #2 = { convergent mustprogress nofree nounwind willreturn memory(read) "approx-func-fp-math"="true" "frame-pointer"="all" "min-legal-vector-width"="64" "no-builtins" "no-infs-fp-math"="true" "no-nans-fp-math"="true" "no-signed-zeros-fp-math"="true" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "unsafe-fp-math"="true" }
attributes #3 = { convergent mustprogress nofree nounwind willreturn memory(argmem: read) }
attributes #4 = { mustprogress nofree nosync nounwind willreturn memory(none) }
attributes #5 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #6 = { nounwind willreturn memory(none) }
attributes #7 = { convergent nounwind willreturn memory(argmem: read) }

!llvm.module.flags = !{!0, !1, !2, !3, !4, !5, !6, !7, !8}
!llvm.ident = !{!9}
!air.version = !{!10}
!air.language_version = !{!11}
!air.compile_options = !{!12, !13, !14}
!air.visible = !{!15}
!air.sampler_states = !{!51}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 27, i32 0]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 7, !"frame-pointer", i32 2}
!3 = !{i32 7, !"air.max_device_buffers", i32 31}
!4 = !{i32 7, !"air.max_constant_buffers", i32 31}
!5 = !{i32 7, !"air.max_threadgroup_buffers", i32 31}
!6 = !{i32 7, !"air.max_textures", i32 128}
!7 = !{i32 7, !"air.max_read_write_textures", i32 8}
!8 = !{i32 7, !"air.max_samplers", i32 16}
!9 = !{!"Apple metal version 32023.921 (metalfe-32023.921.6)"}
!10 = !{i32 2, i32 6, i32 0}
!11 = !{!"Metal", i32 3, i32 1, i32 0}
!12 = !{!"air.compile.denorms_disable"}
!13 = !{!"air.compile.fast_math_enable"}
!14 = !{!"air.compile.framebuffer_fetch_enable"}
!15 = !{ptr @Ripple, !16, !18, !28}
!16 = !{!17}
!17 = !{!"air.visible_output", !"air.arg_type_name", !"half4"}
!18 = !{!19, !20, !21, !22, !23, !24, !25, !26, !27}
!19 = !{i32 0, !"air.visible_input", !"air.arg_type_name", !"float2", !"air.arg_name", !"position"}
!20 = !{i32 1, !"air.visible_input", !"air.arg_type_name", !"texture2d<half, sample>", !"air.arg_name", !"tex"}
!21 = !{i32 2, !"air.visible_input", !"air.arg_type_name", !"float2", !"air.arg_name", !"info"}
!22 = !{i32 3, !"air.visible_input", !"air.arg_type_name", !"float2", !"air.arg_name", !"origin"}
!23 = !{i32 4, !"air.visible_input", !"air.arg_type_name", !"float", !"air.arg_name", !"time"}
!24 = !{i32 5, !"air.visible_input", !"air.arg_type_name", !"float", !"air.arg_name", !"amplitude"}
!25 = !{i32 6, !"air.visible_input", !"air.arg_type_name", !"float", !"air.arg_name", !"frequency"}
!26 = !{i32 7, !"air.visible_input", !"air.arg_type_name", !"float", !"air.arg_name", !"decay"}
!27 = !{i32 8, !"air.visible_input", !"air.arg_type_name", !"float", !"air.arg_name", !"speed"}
!28 = !{!"air.stitching_info", !29, !32, !36, !44, !45, !47, !48, !49, !50}
!29 = !{!"air.stitching_type", !30, ptr @_ZN5metal22_stitching_traits_implIDv4_DhE13load_argumentEPv, ptr @_ZN5metal22_stitching_traits_implIDv4_DhE18store_return_valueEPvS1_, ptr @_ZN5metal22_stitching_traits_implIDv4_DhE7destroyEPv, ptr @_ZN5metal22_stitching_traits_implIDv4_DhE16copy_from_bufferEPvPU11MTLconstantKv}
!30 = !{!"air.vector_type", i32 8, i32 8, null, !31, i32 4}
!31 = !{!"air.half_type", i32 2, i32 2, null}
!32 = !{!"air.stitching_argument", !33, !"position"}
!33 = !{!"air.stitching_type", !34, ptr @_ZN5metal22_stitching_traits_implIDv2_fE13load_argumentEPv, ptr @_ZN5metal22_stitching_traits_implIDv2_fE18store_return_valueEPvS1_, ptr @_ZN5metal22_stitching_traits_implIDv2_fE7destroyEPv, ptr @_ZN5metal22_stitching_traits_implIDv2_fE16copy_from_bufferEPvPU11MTLconstantKv}
!34 = !{!"air.vector_type", i32 8, i32 8, null, !35, i32 2}
!35 = !{!"air.float_type", i32 4, i32 4, null}
!36 = !{!"air.stitching_argument", !37, !"layer"}
!37 = !{!"air.stitching_type", !38, ptr @_ZN5metal22_stitching_traits_implIN7SwiftUI5LayerEE13load_argumentEPv, ptr @_ZN5metal22_stitching_traits_implIN7SwiftUI5LayerEE18store_return_valueEPvS2_, ptr @_ZN5metal22_stitching_traits_implIN7SwiftUI5LayerEE7destroyEPv, ptr @_ZN5metal22_stitching_traits_implIN7SwiftUI5LayerEE16copy_from_bufferEPvPU11MTLconstantKv}
!38 = !{!"air.struct_type", i32 48, i32 8, null, !"SwiftUI::Layer", !39}
!39 = !{!40, !42}
!40 = !{!"air.record_field", i32 0, i32 8, !41, !"tex", null}
!41 = !{!"air.texture_2d_type", i32 8, i32 8, null, !31, !"sample"}
!42 = !{!"air.record_field", i32 8, i32 8, !43, !"info", null}
!43 = !{!"air.array_type", i32 40, i32 8, null, !34, i32 5}
!44 = !{!"air.stitching_argument", !33, !"origin"}
!45 = !{!"air.stitching_argument", !46, !"time"}
!46 = !{!"air.stitching_type", !35, ptr @_ZN5metal22_stitching_traits_implIfE13load_argumentEPv, ptr @_ZN5metal22_stitching_traits_implIfE18store_return_valueEPvf, ptr @_ZN5metal22_stitching_traits_implIfE7destroyEPv, ptr @_ZN5metal22_stitching_traits_implIfE16copy_from_bufferEPvPU11MTLconstantKv}
!47 = !{!"air.stitching_argument", !46, !"amplitude"}
!48 = !{!"air.stitching_argument", !46, !"frequency"}
!49 = !{!"air.stitching_argument", !46, !"decay"}
!50 = !{!"air.stitching_argument", !46, !"speed"}
!51 = !{!"air.sampler_state", ptr addrspace(2) @__air_sampler_state}
!52 = !{!53, !53, i64 0}
!53 = !{!"omnipotent char", !54, i64 0}
!54 = !{!"Simple C++ TBAA"}
!55 = !{!56, !56, i64 0}
!56 = !{!"float", !53, i64 0}
