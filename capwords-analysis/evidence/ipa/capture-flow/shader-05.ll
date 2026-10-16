; ModuleID = 'C:\Users\jdt314\Desktop\rea-work\capwords-analysis\evidence\ipa\capture-flow\shader-05.bc'
source_filename = "dustEffectInitializeParticle"
target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-windows-msvc19.42.34435"

%class.Loki = type { float }
%struct.Particle = type { [2 x float], [2 x float], float }

; Function Attrs: convergent mustprogress nounwind
define void @dustEffectInitializeParticle(ptr addrspace(1) nocapture noundef writeonly "air-buffer-no-alias" %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = alloca %class.Loki, align 4
  %4 = bitcast ptr %3 to ptr
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %4) #6
  call fastcc void @_ZN4LokiC1Ejjj(ptr noundef nonnull %3, i32 noundef %1, i32 noundef 1, i32 noundef 1) #7
  %5 = call fast fastcc float @_ZN4Loki4randEv(ptr noundef nonnull %3) #8
  %6 = fmul fast float %5, 0x401921FB60000000
  %7 = call fast fastcc float @_ZN4Loki4randEv(ptr noundef nonnull %3) #8
  %8 = fmul fast float %7, 4.200000e+01
  %9 = fadd fast float %8, 4.200000e+01
  %10 = call fast float @air.fast_cos.f32(float %6) #9
  %11 = fmul fast float %9, %10
  %12 = call fast float @air.fast_sin.f32(float %6) #9
  %13 = fmul fast float %12, %9
  %14 = call fast fastcc float @_ZN4Loki4randEv(ptr noundef nonnull %3) #8
  %15 = fmul fast float %14, 0x3FE99999A0000000
  %16 = fadd fast float %15, 0x3FE6666660000000
  %17 = zext i32 %1 to i64
  %18 = getelementptr inbounds %struct.Particle, ptr addrspace(1) %0, i64 %17, i32 0, i64 0
  store float 0.000000e+00, ptr addrspace(1) %18, align 4, !tbaa.struct !21, !alias.scope !27
  %19 = getelementptr inbounds %struct.Particle, ptr addrspace(1) %0, i64 %17, i32 0, i64 1
  store float 0.000000e+00, ptr addrspace(1) %19, align 4, !tbaa.struct !30, !alias.scope !27
  %20 = getelementptr inbounds %struct.Particle, ptr addrspace(1) %0, i64 %17, i32 1, i64 0
  store float %11, ptr addrspace(1) %20, align 4, !tbaa.struct !31, !alias.scope !27
  %21 = getelementptr inbounds %struct.Particle, ptr addrspace(1) %0, i64 %17, i32 1, i64 1
  store float %13, ptr addrspace(1) %21, align 4, !tbaa.struct !32, !alias.scope !27
  %22 = getelementptr inbounds %struct.Particle, ptr addrspace(1) %0, i64 %17, i32 2
  store float %16, ptr addrspace(1) %22, align 4, !tbaa.struct !33, !alias.scope !27
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %4) #6
  ret void
}

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(argmem: readwrite)
define internal fastcc float @_ZN4Loki4randEv(ptr nocapture noundef %0) unnamed_addr #1 align 2 {
  %2 = getelementptr inbounds %class.Loki, ptr %0, i64 0, i32 0
  %3 = load float, ptr %2, align 4, !tbaa !34
  %4 = fmul fast float %3, 0x41D060AFC0000000
  %5 = tail call i32 @air.convert.u.i32.f.f32(float %4) #9
  %6 = shl i32 %5, 13
  %7 = xor i32 %6, %5
  %8 = lshr i32 %7, 19
  %9 = shl i32 %5, 12
  %10 = and i32 %9, -1717989376
  %11 = shl i32 %5, 2
  %12 = xor i32 %11, %5
  %13 = lshr i32 %12, 25
  %14 = shl i32 %5, 4
  %15 = and i32 %14, -128
  %16 = or i32 %13, %15
  %17 = shl i32 %5, 3
  %18 = xor i32 %17, %5
  %19 = lshr i32 %18, 11
  %20 = shl i32 %5, 17
  %21 = and i32 %20, 800063488
  %22 = mul i32 %5, 1664525
  %23 = add i32 %22, 1013904223
  %24 = xor i32 %10, %21
  %25 = xor i32 %24, %23
  %26 = xor i32 %25, %19
  %27 = xor i32 %26, %8
  %28 = xor i32 %27, %16
  %29 = tail call fast float @air.convert.f.f32.u.i32(i32 %28) #9
  %30 = fmul fast float %29, 0x3DF0000000000000
  store float %30, ptr %2, align 4, !tbaa !34
  ret float %3
}

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
declare float @air.convert.f.f32.u.i32(i32) local_unnamed_addr #2

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
declare i32 @air.convert.u.i32.f.f32(float) local_unnamed_addr #2

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
declare float @air.fast_sin.f32(float) local_unnamed_addr #2

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
declare float @air.fast_cos.f32(float) local_unnamed_addr #2

; Function Attrs: convergent mustprogress nofree nosync nounwind willreturn memory(argmem: write)
define internal fastcc void @_ZN4LokiC1Ejjj(ptr nocapture noundef writeonly %0, i32 noundef %1, i32 noundef %2, i32 noundef %3) unnamed_addr #3 align 2 {
  tail call fastcc void @_ZN4LokiC2Ejjj(ptr noundef %0, i32 noundef %1, i32 noundef %2, i32 noundef %3) #10
  ret void
}

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(argmem: write)
define internal fastcc void @_ZN4LokiC2Ejjj(ptr nocapture noundef writeonly %0, i32 noundef %1, i32 noundef %2, i32 noundef %3) unnamed_addr #4 align 2 {
  %5 = mul i32 %1, 1099087573
  %6 = mul i32 %2, 1099087573
  %7 = mul i32 %3, 1099087573
  %8 = shl i32 %5, 13
  %9 = xor i32 %8, %5
  %10 = lshr i32 %9, 19
  %11 = shl i32 %5, 12
  %12 = and i32 %11, -1717989376
  %13 = shl i32 %5, 2
  %14 = xor i32 %13, %5
  %15 = lshr i32 %14, 25
  %16 = shl i32 %5, 4
  %17 = and i32 %16, -128
  %18 = or i32 %15, %17
  %19 = shl i32 %5, 3
  %20 = xor i32 %19, %5
  %21 = lshr i32 %20, 11
  %22 = shl i32 %5, 17
  %23 = and i32 %22, 800063488
  %24 = mul i32 %1, 242847441
  %25 = add i32 %24, 1013904223
  %26 = xor i32 %6, %25
  %27 = xor i32 %26, %23
  %28 = xor i32 %27, %12
  %29 = xor i32 %28, %21
  %30 = xor i32 %29, %10
  %31 = xor i32 %30, %18
  %32 = shl i32 %31, 13
  %33 = xor i32 %32, %31
  %34 = lshr i32 %33, 19
  %35 = shl i32 %31, 12
  %36 = and i32 %35, -1717989376
  %37 = shl i32 %31, 2
  %38 = xor i32 %37, %31
  %39 = lshr i32 %38, 25
  %40 = shl i32 %31, 4
  %41 = and i32 %40, -128
  %42 = or i32 %39, %41
  %43 = shl i32 %31, 3
  %44 = xor i32 %43, %31
  %45 = lshr i32 %44, 11
  %46 = shl i32 %31, 17
  %47 = and i32 %46, 800063488
  %48 = mul i32 %31, 1664525
  %49 = add i32 %48, 1013904223
  %50 = xor i32 %47, %7
  %51 = xor i32 %50, %36
  %52 = xor i32 %51, %49
  %53 = xor i32 %52, %45
  %54 = xor i32 %53, %34
  %55 = xor i32 %54, %42
  %56 = shl i32 %55, 13
  %57 = xor i32 %56, %55
  %58 = lshr i32 %57, 19
  %59 = shl i32 %55, 12
  %60 = and i32 %59, -1717989376
  %61 = shl i32 %55, 2
  %62 = xor i32 %61, %55
  %63 = lshr i32 %62, 25
  %64 = shl i32 %55, 4
  %65 = and i32 %64, -128
  %66 = or i32 %63, %65
  %67 = shl i32 %55, 3
  %68 = xor i32 %67, %55
  %69 = lshr i32 %68, 11
  %70 = shl i32 %55, 17
  %71 = and i32 %70, 800063488
  %72 = mul i32 %55, 1664525
  %73 = add i32 %72, 1013904223
  %74 = xor i32 %60, %71
  %75 = xor i32 %74, %73
  %76 = xor i32 %75, %69
  %77 = xor i32 %76, %58
  %78 = xor i32 %77, %66
  %79 = tail call fast float @air.convert.f.f32.u.i32(i32 %78) #9
  %80 = fmul fast float %79, 0x3DF0000000000000
  %81 = getelementptr inbounds %class.Loki, ptr %0, i64 0, i32 0
  store float %80, ptr %81, align 4, !tbaa !34
  ret void
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #5

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #5

attributes #0 = { convergent mustprogress nounwind "approx-func-fp-math"="true" "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-infs-fp-math"="true" "no-nans-fp-math"="true" "no-signed-zeros-fp-math"="true" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "unsafe-fp-math"="true" }
attributes #1 = { mustprogress nofree nosync nounwind willreturn memory(argmem: readwrite) "approx-func-fp-math"="true" "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-infs-fp-math"="true" "no-nans-fp-math"="true" "no-signed-zeros-fp-math"="true" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "unsafe-fp-math"="true" }
attributes #2 = { mustprogress nofree nosync nounwind willreturn memory(none) }
attributes #3 = { convergent mustprogress nofree nosync nounwind willreturn memory(argmem: write) "approx-func-fp-math"="true" "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-infs-fp-math"="true" "no-nans-fp-math"="true" "no-signed-zeros-fp-math"="true" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "unsafe-fp-math"="true" }
attributes #4 = { mustprogress nofree nosync nounwind willreturn memory(argmem: write) "approx-func-fp-math"="true" "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-infs-fp-math"="true" "no-nans-fp-math"="true" "no-signed-zeros-fp-math"="true" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "unsafe-fp-math"="true" }
attributes #5 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #6 = { nounwind }
attributes #7 = { convergent nobuiltin nounwind "no-builtins" }
attributes #8 = { nobuiltin nounwind "no-builtins" }
attributes #9 = { nounwind willreturn memory(none) }
attributes #10 = { nobuiltin "no-builtins" }

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
!15 = !{ptr @dustEffectInitializeParticle, !16, !17}
!16 = !{}
!17 = !{!18, !20}
!18 = !{i32 0, !"air.buffer", !"air.location_index", i32 0, i32 1, !"air.read_write", !"air.address_space", i32 1, !"air.struct_type_info", !19, !"air.arg_type_size", i32 20, !"air.arg_type_align_size", i32 4, !"air.arg_type_name", !"Particle", !"air.arg_name", !"particles"}
!19 = !{i32 0, i32 8, i32 0, !"packed_float2", !"offsetFromBasePosition", i32 8, i32 8, i32 0, !"packed_float2", !"velocity", i32 16, i32 4, i32 0, !"float", !"lifetime"}
!20 = !{i32 1, !"air.thread_position_in_grid", !"air.arg_type_name", !"uint", !"air.arg_name", !"gid"}
!21 = !{i64 0, i64 8, !22, i64 8, i64 8, !22, i64 16, i64 4, !25}
!22 = !{!23, !23, i64 0}
!23 = !{!"omnipotent char", !24, i64 0}
!24 = !{!"Simple C++ TBAA"}
!25 = !{!26, !26, i64 0}
!26 = !{!"float", !23, i64 0}
!27 = !{!28}
!28 = distinct !{!28, !29, !"air-alias-scope-arg(0)"}
!29 = distinct !{!29, !"air-alias-scopes(dustEffectInitializeParticle)"}
!30 = !{i64 0, i64 4, !22, i64 4, i64 8, !22, i64 12, i64 4, !25}
!31 = !{i64 0, i64 8, !22, i64 8, i64 4, !25}
!32 = !{i64 0, i64 4, !22, i64 4, i64 4, !25}
!33 = !{i64 0, i64 4, !25}
!34 = !{!35, !26, i64 0}
!35 = !{!"_ZTS4Loki", !26, i64 0}
