; ModuleID = 'C:\Users\jdt314\Desktop\rea-work\capwords-analysis\evidence\ipa\capture-flow\shader-01.bc'
source_filename = "distortion"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-windows-msvc19.42.34435"

@llvm.compiler.used = appending global [12 x ptr] [ptr @_ZN5metal22_stitching_traits_implIDv2_fE13load_argumentEPv, ptr @_ZN5metal22_stitching_traits_implIDv2_fE16copy_from_bufferEPvPU11MTLconstantKv, ptr @_ZN5metal22_stitching_traits_implIDv2_fE18store_return_valueEPvS1_, ptr @_ZN5metal22_stitching_traits_implIDv2_fE7destroyEPv, ptr @_ZN5metal22_stitching_traits_implIDv4_fE13load_argumentEPv, ptr @_ZN5metal22_stitching_traits_implIDv4_fE16copy_from_bufferEPvPU11MTLconstantKv, ptr @_ZN5metal22_stitching_traits_implIDv4_fE18store_return_valueEPvS1_, ptr @_ZN5metal22_stitching_traits_implIDv4_fE7destroyEPv, ptr @_ZN5metal22_stitching_traits_implIfE13load_argumentEPv, ptr @_ZN5metal22_stitching_traits_implIfE16copy_from_bufferEPvPU11MTLconstantKv, ptr @_ZN5metal22_stitching_traits_implIfE18store_return_valueEPvf, ptr @_ZN5metal22_stitching_traits_implIfE7destroyEPv], section "llvm.metadata"

; Function Attrs: alwaysinline mustprogress nounwind
define internal <2 x float> @_ZN5metal22_stitching_traits_implIDv2_fE13load_argumentEPv(ptr noundef %0) #0 align 2 {
  %2 = bitcast ptr %0 to ptr
  %3 = load <2 x float>, ptr %2, align 8, !tbaa !38
  ret <2 x float> %3
}

; Function Attrs: alwaysinline mustprogress nounwind
define internal void @_ZN5metal22_stitching_traits_implIDv2_fE16copy_from_bufferEPvPU11MTLconstantKv(ptr noundef %0, ptr addrspace(2) noundef %1) #1 align 2 {
  %3 = bitcast ptr %0 to ptr
  %4 = bitcast ptr addrspace(2) %1 to ptr addrspace(2)
  %5 = load <2 x float>, ptr addrspace(2) %4, align 8, !tbaa !38
  store <2 x float> %5, ptr %3, align 8, !tbaa !38
  ret void
}

; Function Attrs: alwaysinline mustprogress nounwind
define internal void @_ZN5metal22_stitching_traits_implIDv2_fE18store_return_valueEPvS1_(ptr noundef %0, <2 x float> noundef %1) #0 align 2 {
  %3 = bitcast ptr %0 to ptr
  store <2 x float> %1, ptr %3, align 8, !tbaa !38
  ret void
}

; Function Attrs: alwaysinline mustprogress nounwind
define internal void @_ZN5metal22_stitching_traits_implIDv2_fE7destroyEPv(ptr noundef %0) #1 align 2 {
  ret void
}

; Function Attrs: alwaysinline mustprogress nounwind
define internal float @_ZN5metal22_stitching_traits_implIfE13load_argumentEPv(ptr noundef %0) #1 align 2 {
  %2 = bitcast ptr %0 to ptr
  %3 = load float, ptr %2, align 4, !tbaa !41
  ret float %3
}

; Function Attrs: alwaysinline mustprogress nounwind
define internal void @_ZN5metal22_stitching_traits_implIfE16copy_from_bufferEPvPU11MTLconstantKv(ptr noundef %0, ptr addrspace(2) noundef %1) #1 align 2 {
  %3 = bitcast ptr %0 to ptr
  %4 = bitcast ptr addrspace(2) %1 to ptr addrspace(2)
  %5 = load float, ptr addrspace(2) %4, align 4, !tbaa !41
  store float %5, ptr %3, align 4, !tbaa !41
  ret void
}

; Function Attrs: alwaysinline mustprogress nounwind
define internal void @_ZN5metal22_stitching_traits_implIfE18store_return_valueEPvf(ptr noundef %0, float noundef %1) #1 align 2 {
  %3 = bitcast ptr %0 to ptr
  store float %1, ptr %3, align 4, !tbaa !41
  ret void
}

; Function Attrs: alwaysinline mustprogress nounwind
define internal void @_ZN5metal22_stitching_traits_implIfE7destroyEPv(ptr noundef %0) #1 align 2 {
  ret void
}

; Function Attrs: alwaysinline mustprogress nounwind
define internal <4 x float> @_ZN5metal22_stitching_traits_implIDv4_fE13load_argumentEPv(ptr noundef %0) #2 align 2 {
  %2 = bitcast ptr %0 to ptr
  %3 = load <4 x float>, ptr %2, align 16, !tbaa !38
  ret <4 x float> %3
}

; Function Attrs: alwaysinline mustprogress nounwind
define internal void @_ZN5metal22_stitching_traits_implIDv4_fE16copy_from_bufferEPvPU11MTLconstantKv(ptr noundef %0, ptr addrspace(2) noundef %1) #1 align 2 {
  %3 = bitcast ptr %0 to ptr
  %4 = bitcast ptr addrspace(2) %1 to ptr addrspace(2)
  %5 = load <4 x float>, ptr addrspace(2) %4, align 16, !tbaa !38
  store <4 x float> %5, ptr %3, align 16, !tbaa !38
  ret void
}

; Function Attrs: alwaysinline mustprogress nounwind
define internal void @_ZN5metal22_stitching_traits_implIDv4_fE18store_return_valueEPvS1_(ptr noundef %0, <4 x float> noundef %1) #2 align 2 {
  %3 = bitcast ptr %0 to ptr
  store <4 x float> %1, ptr %3, align 16, !tbaa !38
  ret void
}

; Function Attrs: alwaysinline mustprogress nounwind
define internal void @_ZN5metal22_stitching_traits_implIDv4_fE7destroyEPv(ptr noundef %0) #1 align 2 {
  ret void
}

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
define <2 x float> @distortion(<2 x float> noundef %0, <4 x float> noundef %1, float noundef %2, float noundef %3, float noundef %4, float noundef %5) local_unnamed_addr #3 {
  %7 = extractelement <4 x float> %1, i64 2
  %8 = extractelement <4 x float> %1, i64 3
  %9 = fmul fast float %3, 0x3FCC28F600000000
  %10 = fmul fast float %7, 5.000000e-01
  %11 = extractelement <2 x float> %0, i64 0
  %12 = fsub fast float %11, %10
  %13 = fmul fast float %4, 4.500000e+00
  %14 = fsub fast float 1.000000e+00, %13
  %15 = fmul fast float %14, %8
  %16 = extractelement <2 x float> %0, i64 1
  %17 = fsub fast float %16, %15
  %18 = fsub fast float %8, %15
  %19 = fdiv fast float %17, %18
  %20 = tail call fast float @air.fast_clamp.f32(float %19, float 0.000000e+00, float 1.000000e+00) #5
  %21 = fmul fast float %20, 6.000000e+00
  %22 = fadd fast float %21, -1.500000e+01
  %23 = fmul fast float %22, %20
  %24 = fadd fast float %23, 1.000000e+01
  %25 = fadd fast float %9, 0x3FD3333340000000
  %26 = fmul fast float %20, %20
  %27 = fmul fast float %26, %25
  %28 = fmul fast float %27, %20
  %29 = fmul fast float %28, %24
  %30 = fadd fast float %29, 1.000000e+00
  %31 = fmul fast float %30, %12
  %32 = fadd fast float %31, %10
  %33 = fmul fast float %4, 5.000000e-01
  %34 = fmul fast float %8, 5.000000e-01
  %35 = fsub fast float %16, %34
  %36 = fadd fast float %33, 1.000000e+00
  %37 = fmul fast float %36, %35
  %38 = fadd fast float %37, %34
  %39 = insertelement <2 x float> undef, float %32, i64 0
  %40 = insertelement <2 x float> %39, float %38, i64 1
  ret <2 x float> %40
}

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
declare float @air.fast_clamp.f32(float, float, float) local_unnamed_addr #4

attributes #0 = { alwaysinline mustprogress nounwind "approx-func-fp-math"="true" "frame-pointer"="all" "min-legal-vector-width"="64" "no-builtins" "no-infs-fp-math"="true" "no-nans-fp-math"="true" "no-signed-zeros-fp-math"="true" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "unsafe-fp-math"="true" }
attributes #1 = { alwaysinline mustprogress nounwind "approx-func-fp-math"="true" "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-infs-fp-math"="true" "no-nans-fp-math"="true" "no-signed-zeros-fp-math"="true" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "unsafe-fp-math"="true" }
attributes #2 = { alwaysinline mustprogress nounwind "approx-func-fp-math"="true" "frame-pointer"="all" "min-legal-vector-width"="128" "no-builtins" "no-infs-fp-math"="true" "no-nans-fp-math"="true" "no-signed-zeros-fp-math"="true" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "unsafe-fp-math"="true" }
attributes #3 = { mustprogress nofree nosync nounwind willreturn memory(none) "approx-func-fp-math"="true" "frame-pointer"="all" "min-legal-vector-width"="128" "no-builtins" "no-infs-fp-math"="true" "no-nans-fp-math"="true" "no-signed-zeros-fp-math"="true" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "unsafe-fp-math"="true" }
attributes #4 = { mustprogress nofree nosync nounwind willreturn memory(none) }
attributes #5 = { nounwind willreturn memory(none) }

!llvm.module.flags = !{!0, !1, !2, !3, !4, !5, !6, !7, !8}
!llvm.ident = !{!9}
!air.version = !{!10}
!air.language_version = !{!11}
!air.compile_options = !{!12, !13, !14}
!air.visible = !{!15}

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
!15 = !{ptr @distortion, !16, !18, !25}
!16 = !{!17}
!17 = !{!"air.visible_output", !"air.arg_type_name", !"float2"}
!18 = !{!19, !20, !21, !22, !23, !24}
!19 = !{i32 0, !"air.visible_input", !"air.arg_type_name", !"float2", !"air.arg_name", !"position"}
!20 = !{i32 1, !"air.visible_input", !"air.arg_type_name", !"float4", !"air.arg_name", !"bounds"}
!21 = !{i32 2, !"air.visible_input", !"air.arg_type_name", !"float", !"air.arg_name", !"centerX"}
!22 = !{i32 3, !"air.visible_input", !"air.arg_type_name", !"float", !"air.arg_name", !"progressX"}
!23 = !{i32 4, !"air.visible_input", !"air.arg_type_name", !"float", !"air.arg_name", !"progressY"}
!24 = !{i32 5, !"air.visible_input", !"air.arg_type_name", !"float", !"air.arg_name", !"progressTranslationY"}
!25 = !{!"air.stitching_info", !26, !29, !30, !33, !35, !36, !37}
!26 = !{!"air.stitching_type", !27, ptr @_ZN5metal22_stitching_traits_implIDv2_fE13load_argumentEPv, ptr @_ZN5metal22_stitching_traits_implIDv2_fE18store_return_valueEPvS1_, ptr @_ZN5metal22_stitching_traits_implIDv2_fE7destroyEPv, ptr @_ZN5metal22_stitching_traits_implIDv2_fE16copy_from_bufferEPvPU11MTLconstantKv}
!27 = !{!"air.vector_type", i32 8, i32 8, null, !28, i32 2}
!28 = !{!"air.float_type", i32 4, i32 4, null}
!29 = !{!"air.stitching_argument", !26, !"position"}
!30 = !{!"air.stitching_argument", !31, !"bounds"}
!31 = !{!"air.stitching_type", !32, ptr @_ZN5metal22_stitching_traits_implIDv4_fE13load_argumentEPv, ptr @_ZN5metal22_stitching_traits_implIDv4_fE18store_return_valueEPvS1_, ptr @_ZN5metal22_stitching_traits_implIDv4_fE7destroyEPv, ptr @_ZN5metal22_stitching_traits_implIDv4_fE16copy_from_bufferEPvPU11MTLconstantKv}
!32 = !{!"air.vector_type", i32 16, i32 16, null, !28, i32 4}
!33 = !{!"air.stitching_argument", !34, !"centerX"}
!34 = !{!"air.stitching_type", !28, ptr @_ZN5metal22_stitching_traits_implIfE13load_argumentEPv, ptr @_ZN5metal22_stitching_traits_implIfE18store_return_valueEPvf, ptr @_ZN5metal22_stitching_traits_implIfE7destroyEPv, ptr @_ZN5metal22_stitching_traits_implIfE16copy_from_bufferEPvPU11MTLconstantKv}
!35 = !{!"air.stitching_argument", !34, !"progressX"}
!36 = !{!"air.stitching_argument", !34, !"progressY"}
!37 = !{!"air.stitching_argument", !34, !"progressTranslationY"}
!38 = !{!39, !39, i64 0}
!39 = !{!"omnipotent char", !40, i64 0}
!40 = !{!"Simple C++ TBAA"}
!41 = !{!42, !42, i64 0}
!42 = !{!"float", !39, i64 0}
