/*
 * Copyright 2025 Marcus Nesse Madland. All rights reserved.
 * License: https://github.com/marcusnessemadland/vulkan-renderer/blob/main/LICENSE
 */

#pragma once

/**
 * Window states.
 *
 */
#define VR_WINDOW_CENTERED			UINT32_C(0x00010000) //!< 
#define VR_WINDOW_RESIZABLE			UINT32_C(0x00020000) //!< 
#define VR_WINDOW_MOVABLE           UINT32_C(0x00030000) //!< 
#define VR_WINDOW_CLOSABLE          UINT32_C(0x00040000) //!< 
#define VR_WINDOW_MINIMIZABLE       UINT32_C(0x00050000) //!< 
#define VR_WINDOW_MAXIMIZABLE       UINT32_C(0x00060000) //!< 
#define VR_WINDOW_CANFULLSCREEN     UINT32_C(0x00070000) //!< 
 /// Default state is enable all
#define VR_WINDOW_DEFAULT (0 \
	| VR_WINDOW_CENTERED \
	| VR_WINDOW_RESIZABLE \
	| VR_WINDOW_MOVABLE \
	| VR_WINDOW_CLOSABLE \
	| VR_WINDOW_MINIMIZABLE \
	| VR_WINDOW_MAXIMIZABLE \
	| VR_WINDOW_CANFULLSCREEN \
	)

/**
 * Material states.
 *
 */
#define VR_MATERIAL_NONE			UINT32_C(0x00000000) //!< 
#define VR_MATERIAL_BLEND			UINT32_C(0x00010000) //!< 
#define VR_MATERIAL_DOUBLE_SIDED	UINT32_C(0x00020000) //!< 