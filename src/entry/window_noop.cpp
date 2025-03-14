/*
 * Copyright 2021 Alain Galvan. All rights reserved.
 * License: https://github.com/alaingalvan/CrossWindow/blob/master/license.md
 */

#ifdef VR_NOOP

#include "NoopWindow.h"

namespace vr
{
Window::~Window() { close(); }

bool Window::create(const WindowDesc& desc, EventQueue& eventQueue)
{
    mDesc = desc;
    return false;
}

void Window::close() {}


const WindowDesc Window::getDesc() { return mDesc; }

void Window::updateDesc(WindowDesc& desc) {}

void Window::setTitle(std::string title) {}

void Window::setPosition(unsigned x, unsigned y) {}

void Window::setMousePosition(unsigned x, unsigned y) {}

void Window::showMouse(bool show) {}

void Window::setSize(unsigned width, unsigned height) {}

void Window::setProgress(float progress) {}

UVec2 Window::getCurrentDisplaySize()
{
    UVec2 v;
    return v;
}

UVec2 Window::getCurrentDisplayPosition()
{
    UVec2 v;
    return v;
}
}

#endif // VR_NOOP