/*
 * Copyright 2025 Marcus Nesse Madland. All rights reserved.
 * License: https://github.com/marcusnessemadland/vulkan-renderer/blob/main/LICENSE
 */

#include "bgfx_utils.h"

#include <bimg/decode.h>
#include <bx/file.h>
#include <bx/readerwriter.h>

#include <unordered_map>
#include <string>

namespace vr
{
	bx::Vec3 toBgfxVec(const Vec3& _v)
	{
		return { _v.x, _v.y, _v.z };
	}

	bx::Quaternion toBgfxQuat(const Quat& _q)
	{
		return { _q.x, _q.y, _q.z, _q.w };
	}

	static void imageReleaseCb(void* _ptr, void* _userData)
	{
		BX_UNUSED(_ptr);
		bimg::ImageContainer* imageContainer = (bimg::ImageContainer*)_userData;
		bimg::imageFree(imageContainer);
	}

	struct Context
	{
		Context()
		{
		}

		void* load(bx::FileReaderI* _reader, const bx::FilePath& _filePath, uint32_t* _size)
		{
			if (bx::open(_reader, _filePath))
			{
				uint32_t size = (uint32_t)bx::getSize(_reader);
				void* data = bx::alloc(&m_allocator, size);
				bx::read(_reader, data, size, bx::ErrorAssert{});
				bx::close(_reader);
				if (NULL != _size)
				{
					*_size = size;
				}
				return data;
			}
			else
			{
				BX_TRACE("Failed to open: %s.", _filePath.getCPtr());
			}

			if (NULL != _size)
			{
				*_size = 0;
			}

			return NULL;
		}

		void unload(void* _ptr)
		{
			bx::free(&m_allocator, _ptr);
		}

		bgfx::TextureHandle loadTexture(const char* _filePath, uint64_t _flags, bgfx::TextureInfo* _info, bimg::Orientation::Enum* _orientation)
		{
			auto it = m_textures.find(_filePath);
			if (it != m_textures.end())
			{
				return it->second; 
			}

			bgfx::TextureHandle handle = BGFX_INVALID_HANDLE;

			uint32_t size;
			void* data = load(&m_reader, _filePath, &size);
			if (NULL != data)
			{
				bimg::ImageContainer* imageContainer = bimg::imageParse(&m_allocator, data, size);

				if (NULL != imageContainer)
				{
					if (NULL != _orientation)
					{
						*_orientation = imageContainer->m_orientation;
					}

					const bgfx::Memory* mem = bgfx::makeRef(
						imageContainer->m_data
						, imageContainer->m_size
						, imageReleaseCb
						, imageContainer
					);
					unload(data);

					if (NULL != _info)
					{
						bgfx::calcTextureSize(
							*_info
							, uint16_t(imageContainer->m_width)
							, uint16_t(imageContainer->m_height)
							, uint16_t(imageContainer->m_depth)
							, imageContainer->m_cubeMap
							, 1 < imageContainer->m_numMips
							, imageContainer->m_numLayers
							, bgfx::TextureFormat::Enum(imageContainer->m_format)
						);
					}

					if (imageContainer->m_cubeMap)
					{
						handle = bgfx::createTextureCube(
							uint16_t(imageContainer->m_width)
							, 1 < imageContainer->m_numMips
							, imageContainer->m_numLayers
							, bgfx::TextureFormat::Enum(imageContainer->m_format)
							, _flags
							, mem
						);
					}
					else if (1 < imageContainer->m_depth)
					{
						handle = bgfx::createTexture3D(
							uint16_t(imageContainer->m_width)
							, uint16_t(imageContainer->m_height)
							, uint16_t(imageContainer->m_depth)
							, 1 < imageContainer->m_numMips
							, bgfx::TextureFormat::Enum(imageContainer->m_format)
							, _flags
							, mem
						);
					}
					else if (bgfx::isTextureValid(0, false, imageContainer->m_numLayers, bgfx::TextureFormat::Enum(imageContainer->m_format), _flags))
					{
						handle = bgfx::createTexture2D(
							uint16_t(imageContainer->m_width)
							, uint16_t(imageContainer->m_height)
							, 1 < imageContainer->m_numMips
							, imageContainer->m_numLayers
							, bgfx::TextureFormat::Enum(imageContainer->m_format)
							, _flags
							, mem
						);
					}

					if (bgfx::isValid(handle))
					{
						const bx::StringView name(_filePath);
						bgfx::setName(handle, name.getPtr(), name.getLength());
					}
				}
			}

			m_textures[_filePath] = handle;
			return handle;
		}

		bx::DefaultAllocator m_allocator;
		bx::FileReader m_reader;
		bx::FileWriter m_writer;

		std::unordered_map<std::string, bgfx::TextureHandle> m_textures;
	};

} // namespace vr

namespace bgfx
{
	static vr::Context* s_ctx = NULL;

	void initBgfxUtils()
	{
		s_ctx = new vr::Context();
	}

	void shutdownBgfxUtils()
	{
		delete s_ctx;
		s_ctx = NULL;
	}

	bgfx::TextureHandle loadTexture(const char* _filePath, uint64_t _flags, bgfx::TextureInfo* _info, bimg::Orientation::Enum* _orientation)
	{
		return s_ctx->loadTexture(_filePath, _flags, _info, _orientation);
	}

} // namespace bgfx