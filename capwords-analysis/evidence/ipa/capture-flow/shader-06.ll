; ModuleID = 'C:\Users\jdt314\Desktop\rea-work\capwords-analysis\evidence\ipa\capture-flow\shader-06.bc'
source_filename = "dustEffectUpdateParticle"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-windows-msvc19.42.34435"

%struct.Particle = type { [2 x float], [2 x float], float }

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(argmem: readwrite)
define void @dustEffectUpdateParticle(ptr addrspace(1) nocapture noundef "air-buffer-no-alias" %0, ptr addrspace(1) nocapture noundef readonly align 8 dereferenceable(8) "air-buffer-no-alias" %1, ptr addrspace(1) nocapture noundef readonly align 4 dereferenceable(4) "air-buffer-no-alias" %2, ptr addrspace(1) nocapture noundef readonly align 4 dereferenceable(4) "air-buffer-no-alias" %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = load <2 x i32>, ptr addrspace(1) %1, align 8, !alias.scope !24, !noalias !27
  %7 = extractelement <2 x i32> %6, i64 0
  %8 = extractelement <2 x i32> %6, i64 1
  %9 = mul i32 %7, %8
  %10 = icmp ugt i32 %9, %4
  br i1 %10, label %11, label %60

11:                                               ; preds = %5
  %12 = load float, ptr addrspace(1) %2, align 4, !tbaa !31, !alias.scope !35, !noalias !36
  %13 = tail call fast float @air.fast_fmin.f32(float 0x3FE99999A0000000, float %12) #2
  %14 = tail call fast float @air.fast_fmax.f32(float 0.000000e+00, float %13) #2
  %15 = urem i32 %4, %7
  %16 = tail call fast float @air.convert.f.f32.u.i32(i32 %15) #2
  %17 = tail call fast float @air.convert.f.f32.u.i32(i32 %7) #2
  %18 = fdiv fast float %16, %17
  %19 = fmul fast float %14, -2.250000e+00
  %20 = fadd fast float %19, 0x3FE99999A0000000
  %21 = fadd fast float %20, %18
  %22 = tail call fast float @air.fast_fmin.f32(float 0x3FE99999A0000000, float %21) #2
  %23 = tail call fast float @air.fast_fmax.f32(float 0.000000e+00, float %22) #2
  %24 = fmul fast float %23, 1.250000e+00
  %25 = fsub fast float 1.000000e+00, %24
  %26 = zext i32 %4 to i64
  %27 = getelementptr inbounds %struct.Particle, ptr addrspace(1) %0, i64 %26, i32 0, i64 0
  %28 = load float, ptr addrspace(1) %27, align 4, !tbaa.struct !37, !alias.scope !39, !noalias !40
  %29 = getelementptr inbounds %struct.Particle, ptr addrspace(1) %0, i64 %26, i32 0, i64 1
  %30 = load float, ptr addrspace(1) %29, align 4, !tbaa.struct !41, !alias.scope !39, !noalias !40
  %31 = getelementptr inbounds %struct.Particle, ptr addrspace(1) %0, i64 %26, i32 1, i64 0
  %32 = load float, ptr addrspace(1) %31, align 4, !tbaa.struct !42, !alias.scope !39, !noalias !40
  %33 = getelementptr inbounds %struct.Particle, ptr addrspace(1) %0, i64 %26, i32 1, i64 1
  %34 = load float, ptr addrspace(1) %33, align 4, !tbaa.struct !43, !alias.scope !39, !noalias !40
  %35 = getelementptr inbounds %struct.Particle, ptr addrspace(1) %0, i64 %26, i32 2
  %36 = load float, ptr addrspace(1) %35, align 4, !tbaa.struct !44, !alias.scope !39, !noalias !40
  %37 = insertelement <2 x float> undef, float %32, i64 0
  %38 = insertelement <2 x float> %37, float %34, i64 1
  %39 = load float, ptr addrspace(1) %3, align 4, !tbaa !31, !alias.scope !45, !noalias !46
  %40 = insertelement <2 x float> poison, float %39, i64 0
  %41 = shufflevector <2 x float> %40, <2 x float> poison, <2 x i32> zeroinitializer
  %42 = insertelement <2 x float> poison, float %25, i64 0
  %43 = shufflevector <2 x float> %42, <2 x float> poison, <2 x i32> zeroinitializer
  %44 = fmul fast <2 x float> %38, %43
  %45 = fmul fast <2 x float> %44, %41
  %46 = insertelement <2 x float> undef, float %28, i64 0
  %47 = insertelement <2 x float> %46, float %30, i64 1
  %48 = fadd fast <2 x float> %45, %47
  %49 = extractelement <2 x float> %48, i64 0
  %50 = extractelement <2 x float> %48, i64 1
  %51 = fmul fast float %39, 1.200000e+02
  %52 = insertelement <2 x float> <float 0.000000e+00, float poison>, float %51, i64 1
  %53 = fmul fast <2 x float> %52, %43
  %54 = fadd fast <2 x float> %53, %38
  %55 = extractelement <2 x float> %54, i64 0
  %56 = extractelement <2 x float> %54, i64 1
  %57 = fmul fast float %39, %25
  %58 = fsub fast float %36, %57
  %59 = tail call fast float @air.fast_fmax.f32(float 0.000000e+00, float %58) #2
  store float %49, ptr addrspace(1) %27, align 4, !tbaa.struct !37, !alias.scope !39, !noalias !40
  store float %50, ptr addrspace(1) %29, align 4, !tbaa.struct !41, !alias.scope !39, !noalias !40
  store float %55, ptr addrspace(1) %31, align 4, !tbaa.struct !42, !alias.scope !39, !noalias !40
  store float %56, ptr addrspace(1) %33, align 4, !tbaa.struct !43, !alias.scope !39, !noalias !40
  store float %59, ptr addrspace(1) %35, align 4, !tbaa.struct !44, !alias.scope !39, !noalias !40
  br label %60

60:                                               ; preds = %11, %5
  ret void
}

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
declare float @air.fast_fmax.f32(float, float) local_unnamed_addr #1

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
declare float @air.fast_fmin.f32(float, float) local_unnamed_addr #1

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
declare float @air.convert.f.f32.u.i32(i32) local_unnamed_addr #1

attributes #0 = { mustprogress nofree nosync nounwind willreturn memory(argmem: readwrite) "approx-func-fp-math"="true" "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-infs-fp-math"="true" "no-nans-fp-math"="true" "no-signed-zeros-fp-math"="true" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "unsafe-fp-math"="true" }
attributes #1 = { mustprogress nofree nosync nounwind willreturn memory(none) }
attributes #2 = { nounwind willreturn memory(none) }

!llvm.module.flags = !{!0, !1, !2, !3, !4, !5, !6, !7, !8}
!llvm.ident = !{!9}
!air.version = !{!10}
!air.language_version = !{!11}
!air.compile_options = !{!12, !13, !14}
!air.kernel = !{!15}

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
!15 = !{ptr @dustEffectUpdateParticle, !16, !17}
!16 = !{}
!17 = !{!18, !20, !21, !22, !23}
!18 = !{i32 0, !"air.buffer", !"air.location_index", i32 0, i32 1, !"air.read_write", !"air.address_space", i32 1, !"air.struct_type_info", !19, !"air.arg_type_size", i32 20, !"air.arg_type_align_size", i32 4, !"air.arg_type_name", !"Particle", !"air.arg_name", !"particles"}
!19 = !{i32 0, i32 8, i32 0, !"packed_float2", !"offsetFromBasePosition", i32 8, i32 8, i32 0, !"packed_float2", !"velocity", i32 16, i32 4, i32 0, !"float", !"lifetime"}
!20 = !{i32 1, !"air.buffer", !"air.buffer_size", i32 8, !"air.location_index", i32 1, i32 1, !"air.read", !"air.address_space", i32 1, !"air.arg_type_size", i32 8, !"air.arg_type_align_size", i32 8, !"air.arg_type_name", !"uint2", !"air.arg_name", !"size"}
!21 = !{i32 2, !"air.buffer", !"air.buffer_size", i32 4, !"air.location_index", i32 2, i32 1, !"air.read", !"air.address_space", i32 1, !"air.arg_type_size", i32 4, !"air.arg_type_align_size", i32 4, !"air.arg_type_name", !"float", !"air.arg_name", !"phase"}
!22 = !{i32 3, !"air.buffer", !"air.buffer_size", i32 4, !"air.location_index", i32 3, i32 1, !"air.read", !"air.address_space", i32 1, !"air.arg_type_size", i32 4, !"air.arg_type_align_size", i32 4, !"air.arg_type_name", !"float", !"air.arg_name", !"timeStep"}
!23 = !{i32 4, !"air.thread_position_in_grid", !"air.arg_type_name", !"uint", !"air.arg_name", !"gid"}
!24 = !{!25}
!25 = distinct !{!25, !26, !"air-alias-scope-arg(1)"}
!26 = distinct !{!26, !"air-alias-scopes(dustEffectUpdateParticle)"}
!27 = !{!28, !29, !30}
!28 = distinct !{!28, !26, !"air-alias-scope-arg(0)"}
!29 = distinct !{!29, !26, !"air-alias-scope-arg(2)"}
!30 = distinct !{!30, !26, !"air-alias-scope-arg(3)"}
!31 = !{!32, !32, i64 0}
!32 = !{!"float", !33, i64 0}
!33 = !{!"omnipotent char", !34, i64 0}
!34 = !{!"Simple C++ TBAA"}
!35 = !{!29}
!36 = !{!28, !25, !30}
!37 = !{i64 0, i64 8, !38, i64 8, i64 8, !38, i64 16, i64 4, !31}
!38 = !{!33, !33, i64 0}
!39 = !{!28}
!40 = !{!25, !29, !30}
!41 = !{i64 0, i64 4, !38, i64 4, i64 8, !38, i64 12, i64 4, !31}
!42 = !{i64 0, i64 8, !38, i64 8, i64 4, !31}
!43 = !{i64 0, i64 4, !38, i64 4, i64 4, !31}
!44 = !{i64 0, i64 4, !31}
!45 = !{!30}
!46 = !{!28, !25, !29}
