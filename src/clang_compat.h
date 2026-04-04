/* Suppress warning from R's own R_ext/Boolean.h which uses
   -Wfixed-enum-extension, a group not recognised by some clang builds. */
#if defined(__clang__)
#  pragma clang diagnostic ignored "-Wunknown-warning-option"
#endif
