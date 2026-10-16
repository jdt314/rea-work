; ModuleID = 'C:\Users\jdt314\Desktop\rea-work\capwords-analysis\evidence\ipa\capture-flow\shader-07.bc'
source_filename = "dustEffectVertex"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-windows-msvc19.42.34435"

%struct.Particle = type { [2 x float], [2 x float], float }
%struct.Rectangle = type { <2 x float>, <2 x float> }

@_ZL12quadVertices = internal unnamed_addr addrspace(2) constant [6 x <2 x float>] [<2 x float> zeroinitializer, <2 x float> <float 1.000000e+00, float 0.000000e+00>, <2 x float> <float 0.000000e+00, float 1.000000e+00>, <2 x float> <float 1.000000e+00, float 0.000000e+00>, <2 x float> <float 0.000000e+00, float 1.000000e+00>, <2 x float> <float 1.000000e+00, float 1.000000e+00>], align 8

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(argmem: read)
define <{ <4 x float>, <2 x float>, float }> @dustEffectVertex(ptr addrspace(1) nocapture noundef readonly align 8 dereferenceable(16) "air-buffer-no-alias" %0, ptr addrspace(1) nocapture noundef readonly align 8 dereferenceable(8) "air-buffer-no-alias" %1, ptr addrspace(1) nocapture noundef readonly align 8 dereferenceable(8) "air-buffer-no-alias" %2, ptr addrspace(1) nocapture noundef readonly "air-buffer-no-alias" %3, i32 noundef %4, i32 noundef %5) local_unnamed_addr #0 {
  %7 = zext i32 %4 to i64
  %8 = getelementptr inbounds [6 x <2 x float>], ptr addrspace(2) @_ZL12quadVertices, i64 0, i64 %7
  %9 = load <2 x float>, ptr addrspace(2) %8, align 8, !tbaa !29
  %10 = load <2 x i32>, ptr addrspace(1) %2, align 8, !alias.scope !32, !noalias !35
  %11 = extractelement <2 x i32> %10, i64 0
  %12 = urem i32 %5, %11
  %13 = udiv i32 %5, %11
  %14 = zext i32 %5 to i64
  %15 = getelementptr inbounds %struct.Particle, ptr addrspace(1) %3, i64 %14, i32 0, i64 0
  %16 = load float, ptr addrspace(1) %15, align 4, !tbaa.struct !39, !alias.scope !42, !noalias !43
  %17 = getelementptr inbounds %struct.Particle, ptr addrspace(1) %3, i64 %14, i32 0, i64 1
  %18 = load float, ptr addrspace(1) %17, align 4, !tbaa.struct !44, !alias.scope !42, !noalias !43
  %19 = getelementptr inbounds %struct.Particle, ptr addrspace(1) %3, i64 %14, i32 2
  %20 = load float, ptr addrspace(1) %19, align 4, !tbaa.struct !45, !alias.scope !42, !noalias !43
  %21 = load <2 x float>, ptr addrspace(1) %1, align 8, !tbaa !29, !alias.scope !46, !noalias !47
  %22 = tail call fast <2 x float> @air.convert.f.v2f32.u.v2i32(<2 x i32> %10) #2
  %23 = fdiv fast <2 x float> %21, %22
  %24 = tail call fast float @air.convert.f.f32.u.i32(i32 %12) #2
  %25 = extractelement <2 x float> %23, i64 0
  %26 = fmul fast float %25, %24
  %27 = insertelement <2 x float> undef, float %26, i64 0
  %28 = tail call fast float @air.convert.f.f32.u.i32(i32 %13) #2
  %29 = extractelement <2 x float> %23, i64 1
  %30 = fmul fast float %28, %29
  %31 = insertelement <2 x float> %27, float %30, i64 1
  %32 = fmul fast <2 x float> %23, %9
  %33 = fadd fast <2 x float> %31, %32
  %34 = fdiv fast <2 x float> %33, %21
  %35 = insertelement <2 x float> undef, float %16, i64 0
  %36 = insertelement <2 x float> %35, float %18, i64 1
  %37 = fadd fast <2 x float> %33, %36
  %38 = getelementptr inbounds %struct.Rectangle, ptr addrspace(1) %0, i64 0, i32 0
  %39 = load <2 x float>, ptr addrspace(1) %38, align 8, !alias.scope !48, !noalias !49
  %40 = extractelement <2 x float> %39, i64 0
  %41 = extractelement <2 x float> %37, i64 0
  %42 = extractelement <2 x float> %21, i64 0
  %43 = getelementptr inbounds %struct.Rectangle, ptr addrspace(1) %0, i64 0, i32 1
  %44 = load <2 x float>, ptr addrspace(1) %43, align 8, !alias.scope !48, !noalias !49
  %45 = extractelement <2 x float> %44, i64 0
  %46 = fmul fast float %41, %45
  %47 = fdiv fast float %46, %42
  %48 = fadd fast float %47, %40
  %49 = extractelement <2 x float> %39, i64 1
  %50 = extractelement <2 x float> %37, i64 1
  %51 = extractelement <2 x float> %21, i64 1
  %52 = extractelement <2 x float> %44, i64 1
  %53 = fmul fast float %50, %52
  %54 = fdiv fast float %53, %51
  %55 = fadd fast float %54, %49
  %56 = fmul fast float %48, 2.000000e+00
  %57 = fadd fast float %56, -1.000000e+00
  %58 = insertelement <4 x float> undef, float %57, i64 0
  %59 = fmul fast float %55, 2.000000e+00
  %60 = fadd fast float %59, -1.000000e+00
  %61 = insertelement <4 x float> %58, float %60, i64 1
  %62 = shufflevector <4 x float> %61, <4 x float> <float poison, float poison, float 0.000000e+00, float 1.000000e+00>, <4 x i32> <i32 0, i32 1, i32 6, i32 7>
  %63 = tail call fast float @air.fast_fmin.f32(float 0x3FD3333340000000, float %20) #2
  %64 = fmul fast float %63, 0x400AAAAAA0000000
  %65 = tail call fast float @air.fast_fmax.f32(float 0.000000e+00, float %64) #2
  %66 = insertvalue <{ <4 x float>, <2 x float>, float }> undef, <4 x float> %62, 0
  %67 = insertvalue <{ <4 x float>, <2 x float>, float }> %66, <2 x float> %34, 1
  %68 = insertvalue <{ <4 x float>, <2 x float>, float }> %67, float %65, 2
  ret <{ <4 x float>, <2 x float>, float }> %68
}

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
declare float @air.fast_fmax.f32(float, float) local_unnamed_addr #1

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
declare float @air.fast_fmin.f32(float, float) local_unnamed_addr #1

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
declare float @air.convert.f.f32.u.i32(i32) local_unnamed_addr #1

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
declare <2 x float> @air.convert.f.v2f32.u.v2i32(<2 x i32>) local_unnamed_addr #1

attributes #0 = { mustprogress nofree nosync nounwind willreturn memory(argmem: read) "approx-func-fp-math"="true" "frame-pointer"="all" "min-legal-vector-width"="64" "no-builtins" "no-infs-fp-math"="true" "no-nans-fp-math"="true" "no-signed-zeros-fp-math"="true" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "unsafe-fp-math"="true" }
attributes #1 = { mustprogress nofree nosync nounwind willreturn memory(none) }
attributes #2 = { nounwind willreturn memory(none) }

!llvm.module.flags = !{!0, !1, !2, !3, !4, !5, !6, !7, !8}
!llvm.ident = !{!9}
!air.version = !{!10}
!air.language_version = !{!11}
!air.compile_options = !{!12, !13, !14}
!air.vertex = !{!15}

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
!15 = !{ptr @dustEffectVertex, !16, !20}
!16 = !{!17, !18, !19}
!17 = !{!"air.position", !"air.arg_type_name", !"float4", !"air.arg_name", !"position"}
!18 = !{!"air.vertex_output", !"generated(2uvDv2_f)", !"air.arg_type_name", !"float2", !"air.arg_name", !"uv"}
!19 = !{!"air.vertex_output", !"generated(5alphaf)", !"air.arg_type_name", !"float", !"air.arg_name", !"alpha"}
!20 = !{!21, !23, !24, !25, !27, !28}
!21 = !{i32 0, !"air.buffer", !"air.buffer_size", i32 16, !"air.location_index", i32 0, i32 1, !"air.read", !"air.address_space", i32 1, !"air.struct_type_info", !22, !"air.arg_type_size", i32 16, !"air.arg_type_align_size", i32 8, !"air.arg_type_name", !"Rectangle", !"air.arg_name", !"rect"}
!22 = !{i32 0, i32 8, i32 0, !"float2", !"origin", i32 8, i32 8, i32 0, !"float2", !"size"}
!23 = !{i32 1, !"air.buffer", !"air.buffer_size", i32 8, !"air.location_index", i32 1, i32 1, !"air.read", !"air.address_space", i32 1, !"air.arg_type_size", i32 8, !"air.arg_type_align_size", i32 8, !"air.arg_type_name", !"float2", !"air.arg_name", !"size"}
!24 = !{i32 2, !"air.buffer", !"air.buffer_size", i32 8, !"air.location_index", i32 2, i32 1, !"air.read", !"air.address_space", i32 1, !"air.arg_type_size", i32 8, !"air.arg_type_align_size", i32 8, !"air.arg_type_name", !"uint2", !"air.arg_name", !"particleResolution"}
!25 = !{i32 3, !"air.buffer", !"air.location_index", i32 3, i32 1, !"air.read", !"air.address_space", i32 1, !"air.struct_type_info", !26, !"air.arg_type_size", i32 20, !"air.arg_type_align_size", i32 4, !"air.arg_type_name", !"Particle", !"air.arg_name", !"particles"}
!26 = !{i32 0, i32 8, i32 0, !"packed_float2", !"offsetFromBasePosition", i32 8, i32 8, i32 0, !"packed_float2", !"velocity", i32 16, i32 4, i32 0, !"float", !"lifetime"}
!27 = !{i32 4, !"air.vertex_id", !"air.arg_type_name", !"uint", !"air.arg_name", !"vid"}
!28 = !{i32 5, !"air.instance_id", !"air.arg_type_name", !"uint", !"air.arg_name", !"particleId"}
!29 = !{!30, !30, i64 0}
!30 = !{!"omnipotent char", !31, i64 0}
!31 = !{!"Simple C++ TBAA"}
!32 = !{!33}
!33 = distinct !{!33, !34, !"air-alias-scope-arg(2)"}
!34 = distinct !{!34, !"air-alias-scopes(dustEffectVertex)"}
!35 = !{!36, !37, !38}
!36 = distinct !{!36, !34, !"air-alias-scope-arg(0)"}
!37 = distinct !{!37, !34, !"air-alias-scope-arg(1)"}
!38 = distinct !{!38, !34, !"air-alias-scope-arg(3)"}
!39 = !{i64 0, i64 8, !29, i64 8, i64 8, !29, i64 16, i64 4, !40}
!40 = !{!41, !41, i64 0}
!41 = !{!"float", !30, i64 0}
!42 = !{!38}
!43 = !{!36, !37, !33}
!44 = !{i64 0, i64 4, !29, i64 4, i64 8, !29, i64 12, i64 4, !40}
!45 = !{i64 0, i64 4, !40}
!46 = !{!37}
!47 = !{!36, !33, !38}
!48 = !{!36}
!49 = !{!37, !33, !38}
