/*
 * SlotOutline with blur behind it.
 *
 * KWin's blur effect blurs one of its own (internal) windows when that
 * window has a "kwin_blur" property; a rect value means the whole window.
 * It only accepts a fixed rect property, so the blurred variant is its own
 * type and Config.outlineBlur picks which one is used.
 */
SlotOutline {
    property rect kwin_blur: Qt.rect(0, 0, 0, 0)
}
