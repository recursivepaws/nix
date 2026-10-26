{
  den.aspects.ollama.nixos =
    { pkgs, config, ... }:
    {
      services.ollama = {
        enable = true;
        # ROCm build on AMD hosts; CUDA skipped since it builds from source without the cuda cache.
        package = if config.hardware.amdgpu.opencl.enable then pkgs.ollama-rocm else pkgs.ollama;
        loadModels = [ "qwen3.5:4b" ];
      };
    };
}
