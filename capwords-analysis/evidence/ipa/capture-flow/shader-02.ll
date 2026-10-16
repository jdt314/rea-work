; ModuleID = 'C:\Users\jdt314\Desktop\rea-work\capwords-analysis\evidence\ipa\capture-flow\shader-02.bc'
source_filename = "captureAperturePaper"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-windows-msvc19.42.34435"

@llvm.compiler.used = appending global [12 x ptr] [ptr @_ZN5metal22_stitching_traits_implIDv2_fE13load_argumentEPv, ptr @_ZN5metal22_stitching_traits_implIDv2_fE16copy_from_bufferEPvPU11MTLconstantKv, ptr @_ZN5metal22_stitching_traits_implIDv2_fE18store_return_valueEPvS1_, ptr @_ZN5metal22_stitching_traits_implIDv2_fE7destroyEPv, ptr @_ZN5metal22_stitching_traits_implIDv4_DhE13load_argumentEPv, ptr @_ZN5metal22_stitching_traits_implIDv4_DhE16copy_from_bufferEPvPU11MTLconstantKv, ptr @_ZN5metal22_stitching_traits_implIDv4_DhE18store_return_valueEPvS1_, ptr @_ZN5metal22_stitching_traits_implIDv4_DhE7destroyEPv, ptr @_ZN5metal22_stitching_traits_implIfE13load_argumentEPv, ptr @_ZN5metal22_stitching_traits_implIfE16copy_from_bufferEPvPU11MTLconstantKv, ptr @_ZN5metal22_stitching_traits_implIfE18store_return_valueEPvf, ptr @_ZN5metal22_stitching_traits_implIfE7destroyEPv], section "llvm.metadata"

; Function Attrs: alwaysinline mustprogress nounwind
define internal <2 x float> @_ZN5metal22_stitching_traits_implIDv2_fE13load_argumentEPv(ptr noundef %0) #0 align 2 {
  %2 = bitcast ptr %0 to ptr
  %3 = load <2 x float>, ptr %2, align 8, !tbaa !39
  ret <2 x float> %3
}

; Function Attrs: alwaysinline mustprogress nounwind
define internal void @_ZN5metal22_stitching_traits_implIDv2_fE16copy_from_bufferEPvPU11MTLconstantKv(ptr noundef %0, ptr addrspace(2) noundef %1) #1 align 2 {
  %3 = bitcast ptr %0 to ptr
  %4 = bitcast ptr addrspace(2) %1 to ptr addrspace(2)
  %5 = load <2 x float>, ptr addrspace(2) %4, align 8, !tbaa !39
  store <2 x float> %5, ptr %3, align 8, !tbaa !39
  ret void
}

; Function Attrs: alwaysinline mustprogress nounwind
define internal void @_ZN5metal22_stitching_traits_implIDv2_fE18store_return_valueEPvS1_(ptr noundef %0, <2 x float> noundef %1) #0 align 2 {
  %3 = bitcast ptr %0 to ptr
  store <2 x float> %1, ptr %3, align 8, !tbaa !39
  ret void
}

; Function Attrs: alwaysinline mustprogress nounwind
define internal void @_ZN5metal22_stitching_traits_implIDv2_fE7destroyEPv(ptr noundef %0) #1 align 2 {
  ret void
}

; Function Attrs: alwaysinline mustprogress nounwind
define internal <4 x half> @_ZN5metal22_stitching_traits_implIDv4_DhE13load_argumentEPv(ptr noundef %0) #0 align 2 {
  %2 = bitcast ptr %0 to ptr
  %3 = load <4 x half>, ptr %2, align 8, !tbaa !39
  ret <4 x half> %3
}

; Function Attrs: alwaysinline mustprogress nounwind
define internal void @_ZN5metal22_stitching_traits_implIDv4_DhE16copy_from_bufferEPvPU11MTLconstantKv(ptr noundef %0, ptr addrspace(2) noundef %1) #1 align 2 {
  %3 = bitcast ptr %0 to ptr
  %4 = bitcast ptr addrspace(2) %1 to ptr addrspace(2)
  %5 = load <4 x half>, ptr addrspace(2) %4, align 8, !tbaa !39
  store <4 x half> %5, ptr %3, align 8, !tbaa !39
  ret void
}

; Function Attrs: alwaysinline mustprogress nounwind
define internal void @_ZN5metal22_stitching_traits_implIDv4_DhE18store_return_valueEPvS1_(ptr noundef %0, <4 x half> noundef %1) #0 align 2 {
  %3 = bitcast ptr %0 to ptr
  store <4 x half> %1, ptr %3, align 8, !tbaa !39
  ret void
}

; Function Attrs: alwaysinline mustprogress nounwind
define internal void @_ZN5metal22_stitching_traits_implIDv4_DhE7destroyEPv(ptr noundef %0) #1 align 2 {
  ret void
}

; Function Attrs: alwaysinline mustprogress nounwind
define internal float @_ZN5metal22_stitching_traits_implIfE13load_argumentEPv(ptr noundef %0) #1 align 2 {
  %2 = bitcast ptr %0 to ptr
  %3 = load float, ptr %2, align 4, !tbaa !42
  ret float %3
}

; Function Attrs: alwaysinline mustprogress nounwind
define internal void @_ZN5metal22_stitching_traits_implIfE16copy_from_bufferEPvPU11MTLconstantKv(ptr noundef %0, ptr addrspace(2) noundef %1) #1 align 2 {
  %3 = bitcast ptr %0 to ptr
  %4 = bitcast ptr addrspace(2) %1 to ptr addrspace(2)
  %5 = load float, ptr addrspace(2) %4, align 4, !tbaa !42
  store float %5, ptr %3, align 4, !tbaa !42
  ret void
}

; Function Attrs: alwaysinline mustprogress nounwind
define internal void @_ZN5metal22_stitching_traits_implIfE18store_return_valueEPvf(ptr noundef %0, float noundef %1) #1 align 2 {
  %3 = bitcast ptr %0 to ptr
  store float %1, ptr %3, align 4, !tbaa !42
  ret void
}

; Function Attrs: alwaysinline mustprogress nounwind
define internal void @_ZN5metal22_stitching_traits_implIfE7destroyEPv(ptr noundef %0) #1 align 2 {
  ret void
}

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
define <4 x half> @captureAperturePaper(<2 x float> noundef %0, <4 x half> noundef %1, <4 x half> noundef %2, float noundef %3, float noundef %4, float noundef %5) local_unnamed_addr #2 {
  %7 = extractelement <4 x half> %1, i64 3
  %8 = fcmp fast ugt half %7, 0xH0000
  br i1 %8, label %9, label %53

9:                                                ; preds = %6
  %10 = shufflevector <4 x half> %1, <4 x half> poison, <3 x i32> <i32 0, i32 1, i32 2>
  %11 = shufflevector <4 x half> %1, <4 x half> undef, <3 x i32> <i32 3, i32 3, i32 3>
  %12 = fdiv fast <3 x half> %10, %11
  %13 = extractelement <3 x half> %12, i64 0
  %14 = extractelement <3 x half> %12, i64 1
  %15 = extractelement <3 x half> %12, i64 2
  %16 = tail call fast half @air.fmin.f16(half %14, half %15) #4
  %17 = tail call fast half @air.fmin.f16(half %13, half %16) #4
  %18 = fadd fast half %17, 0xHBB85
  %19 = fmul fast half %18, 0xH4CF9
  %20 = tail call fast half @air.clamp.f16(half %19, half 0xH0000, half 0xH3C00) #4
  %21 = fmul fast half %20, %20
  %22 = fmul fast half %20, 0xH4000
  %23 = fsub fast half 0xH4200, %22
  %24 = fmul fast half %21, %23
  %25 = shufflevector <4 x half> %2, <4 x half> poison, <3 x i32> <i32 0, i32 1, i32 2>
  %26 = extractelement <4 x half> %2, i64 3
  %27 = tail call fast half @air.fmax.f16(half %26, half 0xH068E) #4
  %28 = insertelement <3 x half> poison, half %27, i64 0
  %29 = shufflevector <3 x half> %28, <3 x half> poison, <3 x i32> zeroinitializer
  %30 = fdiv fast <3 x half> %25, %29
  %31 = fmul fast <3 x half> %12, <half 0xH3A8F, half 0xH3A8F, half 0xH3A8F>
  %32 = fadd fast <3 x half> %31, <half 0xH249C, half 0xH249C, half 0xH249C>
  %33 = fptrunc float %5 to half
  %34 = insertelement <3 x half> poison, half %33, i64 0
  %35 = shufflevector <3 x half> %34, <3 x half> poison, <3 x i32> zeroinitializer
  %36 = tail call fast <3 x half> @air.mix.v3f16(<3 x half> %12, <3 x half> %32, <3 x half> %35) #4
  %37 = fptrunc float %3 to half
  %38 = insertelement <3 x half> poison, half %37, i64 0
  %39 = shufflevector <3 x half> %38, <3 x half> poison, <3 x i32> zeroinitializer
  %40 = tail call fast <3 x half> @air.mix.v3f16(<3 x half> %12, <3 x half> %36, <3 x half> %39) #4
  %41 = fptrunc float %4 to half
  %42 = insertelement <3 x half> poison, half %41, i64 0
  %43 = shufflevector <3 x half> %42, <3 x half> poison, <3 x i32> zeroinitializer
  %44 = fadd fast <3 x half> %40, %43
  %45 = tail call fast <3 x half> @air.clamp.v3f16(<3 x half> %44, <3 x half> zeroinitializer, <3 x half> <half 0xH3C00, half 0xH3C00, half 0xH3C00>) #4
  %46 = tail call fast <3 x half> @air.mix.v3f16(<3 x half> %12, <3 x half> %30, <3 x half> %39) #4
  %47 = insertelement <3 x half> poison, half %24, i64 0
  %48 = shufflevector <3 x half> %47, <3 x half> poison, <3 x i32> zeroinitializer
  %49 = tail call fast <3 x half> @air.mix.v3f16(<3 x half> %45, <3 x half> %46, <3 x half> %48) #4
  %50 = fmul fast <3 x half> %49, %11
  %51 = shufflevector <3 x half> %50, <3 x half> poison, <4 x i32> <i32 0, i32 1, i32 2, i32 poison>
  %52 = shufflevector <4 x half> %51, <4 x half> %1, <4 x i32> <i32 0, i32 1, i32 2, i32 7>
  br label %53

53:                                               ; preds = %9, %6
  %54 = phi <4 x half> [ %52, %9 ], [ %1, %6 ]
  ret <4 x half> %54
}

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
declare <3 x half> @air.mix.v3f16(<3 x half>, <3 x half>, <3 x half>) local_unnamed_addr #3

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
declare <3 x half> @air.clamp.v3f16(<3 x half>, <3 x half>, <3 x half>) local_unnamed_addr #3

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
declare half @air.fmax.f16(half, half) local_unnamed_addr #3

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
declare half @air.clamp.f16(half, half, half) local_unnamed_addr #3

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
declare half @air.fmin.f16(half, half) local_unnamed_addr #3

attributes #0 = { alwaysinline mustprogress nounwind "approx-func-fp-math"="true" "frame-pointer"="all" "min-legal-vector-width"="64" "no-builtins" "no-infs-fp-math"="true" "no-nans-fp-math"="true" "no-signed-zeros-fp-math"="true" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "unsafe-fp-math"="true" }
attributes #1 = { alwaysinline mustprogress nounwind "approx-func-fp-math"="true" "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-infs-fp-math"="true" "no-nans-fp-math"="true" "no-signed-zeros-fp-math"="true" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "unsafe-fp-math"="true" }
attributes #2 = { mustprogress nofree nosync nounwind willreturn memory(none) "approx-func-fp-math"="true" "frame-pointer"="all" "min-legal-vector-width"="64" "no-builtins" "no-infs-fp-math"="true" "no-nans-fp-math"="true" "no-signed-zeros-fp-math"="true" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "unsafe-fp-math"="true" }
attributes #3 = { mustprogress nofree nosync nounwind willreturn memory(none) }
attributes #4 = { nounwind willreturn memory(none) }

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
!15 = !{ptr @captureAperturePaper, !16, !18, !25}
!16 = !{!17}
!17 = !{!"air.visible_output", !"air.arg_type_name", !"half4"}
!18 = !{!19, !20, !21, !22, !23, !24}
!19 = !{i32 0, !"air.visible_input", !"air.arg_type_name", !"float2", !"air.arg_name", !"position"}
!20 = !{i32 1, !"air.visible_input", !"air.arg_type_name", !"half4", !"air.arg_name", !"source"}
!21 = !{i32 2, !"air.visible_input", !"air.arg_type_name", !"half4", !"air.arg_name", !"paper"}
!22 = !{i32 3, !"air.visible_input", !"air.arg_type_name", !"float", !"air.arg_name", !"paperAmount"}
!23 = !{i32 4, !"air.visible_input", !"air.arg_type_name", !"float", !"air.arg_name", !"brightness"}
!24 = !{i32 5, !"air.visible_input", !"air.arg_type_name", !"float", !"air.arg_name", !"bladeSoftening"}
!25 = !{!"air.stitching_info", !26, !29, !33, !34, !35, !37, !38}
!26 = !{!"air.stitching_type", !27, ptr @_ZN5metal22_stitching_traits_implIDv4_DhE13load_argumentEPv, ptr @_ZN5metal22_stitching_traits_implIDv4_DhE18store_return_valueEPvS1_, ptr @_ZN5metal22_stitching_traits_implIDv4_DhE7destroyEPv, ptr @_ZN5metal22_stitching_traits_implIDv4_DhE16copy_from_bufferEPvPU11MTLconstantKv}
!27 = !{!"air.vector_type", i32 8, i32 8, null, !28, i32 4}
!28 = !{!"air.half_type", i32 2, i32 2, null}
!29 = !{!"air.stitching_argument", !30, !"position"}
!30 = !{!"air.stitching_type", !31, ptr @_ZN5metal22_stitching_traits_implIDv2_fE13load_argumentEPv, ptr @_ZN5metal22_stitching_traits_implIDv2_fE18store_return_valueEPvS1_, ptr @_ZN5metal22_stitching_traits_implIDv2_fE7destroyEPv, ptr @_ZN5metal22_stitching_traits_implIDv2_fE16copy_from_bufferEPvPU11MTLconstantKv}
!31 = !{!"air.vector_type", i32 8, i32 8, null, !32, i32 2}
!32 = !{!"air.float_type", i32 4, i32 4, null}
!33 = !{!"air.stitching_argument", !26, !"source"}
!34 = !{!"air.stitching_argument", !26, !"paper"}
!35 = !{!"air.stitching_argument", !36, !"paperAmount"}
!36 = !{!"air.stitching_type", !32, ptr @_ZN5metal22_stitching_traits_implIfE13load_argumentEPv, ptr @_ZN5metal22_stitching_traits_implIfE18store_return_valueEPvf, ptr @_ZN5metal22_stitching_traits_implIfE7destroyEPv, ptr @_ZN5metal22_stitching_traits_implIfE16copy_from_bufferEPvPU11MTLconstantKv}
!37 = !{!"air.stitching_argument", !36, !"brightness"}
!38 = !{!"air.stitching_argument", !36, !"bladeSoftening"}
!39 = !{!40, !40, i64 0}
!40 = !{!"omnipotent char", !41, i64 0}
!41 = !{!"Simple C++ TBAA"}
!42 = !{!43, !43, i64 0}
!43 = !{!"float", !40, i64 0}
