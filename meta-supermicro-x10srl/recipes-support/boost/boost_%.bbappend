# AST2400 is armv5e. Boost.Context emits text relocations on this ABI,
# and Yocto treats [textrel] as a fatal QA error.
INSANE_SKIP:${PN}-context += "textrel"
INSANE_SKIP:${PN}-dbg += "textrel"
