/*
 * Copyright 2025 Marcus Nesse Madland. All rights reserved.
 * License: https://github.com/marcusnessemadland/vulkan-renderer/blob/main/LICENSE
 */

#pragma once

#include <bgfx/bgfx.h>

#include <memory>

namespace vr
{
    struct GBufferAttachment 
    {
        // @todo Consider computing Fresnel reflectance in shader instead of storing it
        enum Enum
        {
            DiffuseRoughness,  // .rgb = Diffuse color, .a = Roughness squared (remapped roughness)
            EncodedNormal,     // .rg  = Encoded normal (compressed normal vector)
            FresnelMetallic,   // .rgb = Fresnel reflectance at normal incidence, .a = metallic factor
            EmissiveOcclusion, // .rgb = Emissive radiance, .a = Ambient occlusion multiplier
            Depth,             // .r   = Depth value

            Count
        };
    };

    class World;
    class Material;
    class Texture;

	struct CommonResources;

	class GBuffer
	{
        friend class ToneMapping;

        void createFramebuffer();
        void destroyFramebuffer();

        void setMaterial(std::shared_ptr<Material> _material);
        bool setTextureOrDefault(uint8_t stage, bgfx::UniformHandle uniform, std::shared_ptr<Texture> texture);
        void submit(const World* _world);

	public:
		GBuffer(bgfx::ViewId _view, const CommonResources* _common);
		~GBuffer();

		void render(const World* _world);

	private:
		bgfx::ViewId m_view;
		const CommonResources* m_common;

        bool multipleScatteringEnabled = true;
        bool whiteFurnaceEnabled = false;

        bgfx::FrameBufferHandle m_framebuffer;
		bgfx::ProgramHandle m_program;
        bgfx::TextureHandle m_defaultTexture;
        bgfx::UniformHandle m_normalMatrixUniform;
        bgfx::UniformHandle m_baseColorFactorUniform;
        bgfx::UniformHandle m_metRoughNorOccFactorUniform;
        bgfx::UniformHandle m_emissiveFactorUniform;
        bgfx::UniformHandle m_hasTexturesUniform;
        bgfx::UniformHandle m_multipleScatteringUniform;
        bgfx::UniformHandle m_baseColorSampler;
        bgfx::UniformHandle m_metallicRoughnessSampler;
        bgfx::UniformHandle m_normalSampler;
        bgfx::UniformHandle m_occlusionSampler;
        bgfx::UniformHandle m_emissiveSampler;
	};

} // namespace vr