set(LIBTBL_SRCS Constants.swift DMGManager.swift Downloader.swift Installer.swift Settings.swift
                Utils.swift)
add_library(${LIBTBL} STATIC ${LIBTBL_SRCS})
