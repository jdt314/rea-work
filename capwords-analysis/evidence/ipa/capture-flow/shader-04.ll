; ModuleID = 'C:\Users\jdt314\Desktop\rea-work\capwords-analysis\evidence\ipa\capture-flow\shader-04.bc'
source_filename = "softPaperArtwork"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-windows-msvc19.42.34435"

@llvm.compiler.used = appending global [8 x ptr] [ptr @_ZN5metal22_stitching_traits_implIDv2_fE13load_argumentEPv, ptr @_ZN5metal22_stitching_traits_implIDv2_fE16copy_from_bufferEPvPU11MTLconstantKv, ptr @_ZN5metal22_stitching_traits_implIDv2_fE18store_return_valueEPvS1_, ptr @_ZN5metal22_stitching_traits_implIDv2_fE7destroyEPv, ptr @_ZN5metal22_stitching_traits_implIDv4_DhE13load_argumentEPv, ptr @_ZN5metal22_stitching_traits_implIDv4_DhE16copy_from_bufferEPvPU11MTLconstantKv, ptr @_ZN5metal22_stitching_traits_implIDv4_DhE18store_return_valueEPvS1_, ptr @_ZN5metal22_stitching_traits_implIDv4_DhE7destroyEPv], section "llvm.metadata"

; Function Attrs: alwaysinline mustprogress nounwind
define internal <2 x float> @_ZN5metal22_stitching_traits_implIDv2_fE13load_argumentEPv(ptr noundef %0) #0 align 2 {
  %2 = bitcast ptr %0 to ptr
  %3 = load <2 x float>, ptr %2, align 8, !tbaa !30
  ret <2 x float> %3
}

; Function Attrs: alwaysinline mustprogress nounwind
define internal void @_ZN5metal22_stitching_traits_implIDv2_fE16copy_from_bufferEPvPU11MTLconstantKv(ptr noundef %0, ptr addrspace(2) noundef %1) #1 align 2 {
  %3 = bitcast ptr %0 to ptr
  %4 = bitcast ptr addrspace(2) %1 to ptr addrspace(2)
  %5 = load <2 x float>, ptr addrspace(2) %4, align 8, !tbaa !30
  store <2 x float> %5, ptr %3, align 8, !tbaa !30
  ret void
}

; Function Attrs: alwaysinline mustprogress nounwind
define internal void @_ZN5metal22_stitching_traits_implIDv2_fE18store_return_valueEPvS1_(ptr noundef %0, <2 x float> noundef %1) #0 align 2 {
  %3 = bitcast ptr %0 to ptr
  store <2 x float> %1, ptr %3, align 8, !tbaa !30
  ret void
}

; Function Attrs: alwaysinline mustprogress nounwind
define internal void @_ZN5metal22_stitching_traits_implIDv2_fE7destroyEPv(ptr noundef %0) #1 align 2 {
  ret void
}

; Function Attrs: alwaysinline mustprogress nounwind
define internal <4 x half> @_ZN5metal22_stitching_traits_implIDv4_DhE13load_argumentEPv(ptr noundef %0) #0 align 2 {
  %2 = bitcast ptr %0 to ptr
  %3 = load <4 x half>, ptr %2, align 8, !tbaa !30
  ret <4 x half> %3
}

; Function Attrs: alwaysinline mustprogress nounwind
define internal void @_ZN5metal22_stitching_traits_implIDv4_DhE16copy_from_bufferEPvPU11MTLconstantKv(ptr noundef %0, ptr addrspace(2) noundef %1) #1 align 2 {
  %3 = bitcast ptr %0 to ptr
  %4 = bitcast ptr addrspace(2) %1 to ptr addrspace(2)
  %5 = load <4 x half>, ptr addrspace(2) %4, align 8, !tbaa !30
  store <4 x half> %5, ptr %3, align 8, !tbaa !30
  ret void
}

; Function Attrs: alwaysinline mustprogress nounwind
define internal void @_ZN5metal22_stitching_traits_implIDv4_DhE18store_return_valueEPvS1_(ptr noundef %0, <4 x half> noundef %1) #0 align 2 {
  %3 = bitcast ptr %0 to ptr
  store <4 x half> %1, ptr %3, align 8, !tbaa !30
  ret void
}

; Function Attrs: alwaysinline mustprogress nounwind
define internal void @_ZN5metal22_stitching_traits_implIDv4_DhE7destroyEPv(ptr noundef %0) #1 align 2 {
  ret void
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none)
define <4 x half> @softPaperArtwork(<2 x float> noundef %0, <4 x half> noundef %1) local_unnamed_addr #2 {
  %3 = shufflevector <4 x half> %1, <4 x half> poison, <3 x i32> <i32 0, i32 1, i32 2>
  %4 = fmul fast <3 x half> %3, <half 0xH3A8F, half 0xH3A8F, half 0xH3A8F>
  %5 = extractelement <4 x half> %1, i64 3
  %6 = fmul fast half %5, 0xH249C
  %7 = insertelement <3 x half> poison, half %6, i64 0
  %8 = shufflevector <3 x half> %7, <3 x half> poison, <3 x i32> zeroinitializer
  %9 = fadd fast <3 x half> %8, %4
  %10 = shufflevector <3 x half> %9, <3 x half> poison, <4 x i32> <i32 0, i32 1, i32 2, i32 poison>
  %11 = shufflevector <4 x half> %10, <4 x half> %1, <4 x i32> <i32 0, i32 1, i32 2, i32 7>
  ret <4 x half> %11
}

attributes #0 = { alwaysinline mustprogress nounwind "approx-func-fp-math"="true" "frame-pointer"="all" "min-legal-vector-width"="64" "no-builtins" "no-infs-fp-math"="true" "no-nans-fp-math"="true" "no-signed-zeros-fp-math"="true" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "unsafe-fp-math"="true" }
attributes #1 = { alwaysinline mustprogress nounwind "approx-func-fp-math"="true" "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-infs-fp-math"="true" "no-nans-fp-math"="true" "no-signed-zeros-fp-math"="true" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "unsafe-fp-math"="true" }
attributes #2 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) "approx-func-fp-math"="true" "frame-pointer"="all" "min-legal-vector-width"="64" "no-builtins" "no-infs-fp-math"="true" "no-nans-fp-math"="true" "no-signed-zeros-fp-math"="true" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "unsafe-fp-math"="true" }

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
!15 = !{ptr @softPaperArtwork, !16, !18, !21}
!16 = !{!17}
!17 = !{!"air.visible_output", !"air.arg_type_name", !"half4"}
!18 = !{!19, !20}
!19 = !{i32 0, !"air.visible_input", !"air.arg_type_name", !"float2", !"air.arg_name", !"position"}
!20 = !{i32 1, !"air.visible_input", !"air.arg_type_name", !"half4", !"air.arg_name", !"source"}
!21 = !{!"air.stitching_info", !22, !25, !29}
!22 = !{!"air.stitching_type", !23, ptr @_ZN5metal22_stitching_traits_implIDv4_DhE13load_argumentEPv, ptr @_ZN5metal22_stitching_traits_implIDv4_DhE18store_return_valueEPvS1_, ptr @_ZN5metal22_stitching_traits_implIDv4_DhE7destroyEPv, ptr @_ZN5metal22_stitching_traits_implIDv4_DhE16copy_from_bufferEPvPU11MTLconstantKv}
!23 = !{!"air.vector_type", i32 8, i32 8, null, !24, i32 4}
!24 = !{!"air.half_type", i32 2, i32 2, null}
!25 = !{!"air.stitching_argument", !26, !"position"}
!26 = !{!"air.stitching_type", !27, ptr @_ZN5metal22_stitching_traits_implIDv2_fE13load_argumentEPv, ptr @_ZN5metal22_stitching_traits_implIDv2_fE18store_return_valueEPvS1_, ptr @_ZN5metal22_stitching_traits_implIDv2_fE7destroyEPv, ptr @_ZN5metal22_stitching_traits_implIDv2_fE16copy_from_bufferEPvPU11MTLconstantKv}
!27 = !{!"air.vector_type", i32 8, i32 8, null, !28, i32 2}
!28 = !{!"air.float_type", i32 4, i32 4, null}
!29 = !{!"air.stitching_argument", !22, !"source"}
!30 = !{!31, !31, i64 0}
!31 = !{!"omnipotent char", !32, i64 0}
!32 = !{!"Simple C++ TBAA"}
