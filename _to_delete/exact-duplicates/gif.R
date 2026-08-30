rm(list = ls())


# Set up parallel processing
options(mc.cores = parallel::detectCores() - 1)
library(doParallel)
library(foreach)
Clusters <- makeCluster(detectCores() - 1)

library(magick)

# Stop any current operations first
cat("Starting simple approach...\n")

gif_file <- "pak_map.gif"

# ---- Method: Read one frame at a time using index ----
cat("Attempting to read GIF frame by frame...\n")

tryCatch({
  # First, try to get the total number of frames without loading all
  test_read <- image_read(gif_file)
  total_frames <- length(test_read)
  cat("Total frames detected:", total_frames, "\n")

  # Clear from memory immediately
  rm(test_read)
  gc()

  # Calculate how many frames to actually process (max 30 for speed)
  max_process <- 30
  frame_step <- max(1, total_frames %/% max_process)
  frame_indices <- seq(1, total_frames, by = frame_step)[1:max_process]

  cat("Will process", length(frame_indices), "frames (every", frame_step, "frame)\n")

  # Process frames one by one
  processed_frames <- list()

  # Define text overlays
  overlay_texts <- list(
    list(start = 1, end = 6, text = "Where do 240 million Pakistanis live?"),
    list(start = 7, end = 12, text = "Dense clusters → jobs, markets, innovation"),
    list(start = 13, end = 18, text = "Low-density areas → resources, untapped potential"),
    list(start = 19, end = 24, text = "Each dot = 100,000 people"),
    list(start = 25, end = 30, text = "Density drives development — but no region should be left behind.")
  )

  watermark <- "📊 DataViz by Zahid Asghar"

  for (i in seq_along(frame_indices)) {
    cat("Processing frame", i, "of", length(frame_indices), "\r")

    # Read just this one frame
    frame_idx <- frame_indices[i]
    single_frame <- image_read(gif_file)[frame_idx]

    # Resize immediately
    single_frame <- image_scale(single_frame, "500x")

    # Add watermark
    single_frame <- image_annotate(single_frame, watermark,
                                   size = 14,
                                   gravity = "southeast",
                                   color = "white",
                                   strokecolor = "black", strokewidth = 1)

    # Add overlay text based on position
    for (txt in overlay_texts) {
      if (i >= txt$start && i <= txt$end) {
        single_frame <- image_annotate(single_frame, txt$text,
                                       size = 18,
                                       gravity = "center",
                                       color = "white",
                                       strokecolor = "black", strokewidth = 2)
        break  # Only one text per frame
      }
    }

    processed_frames[[i]] <- single_frame

    # Clean up
    rm(single_frame)
    if (i %% 5 == 0) gc()  # Garbage collect every 5 frames
  }

  cat("\nCombining frames...\n")

  # Create final GIF
  final_gif <- image_join(processed_frames)
  final_gif <- image_animate(final_gif, fps = 6, loop = 0)

  # Save with high compression
  output_file <- "pakistan_simple_output.gif"
  image_write(final_gif, output_file, quality = 40)

  cat("✓ SUCCESS! Created:", output_file, "\n")
  cat("File size:", round(file.info(output_file)$size / 1024^2, 2), "MB\n")

}, error = function(e) {
  cat("\nFrame-by-frame approach failed:", e$message, "\n")
  cat("Trying emergency minimal approach...\n")

  # Emergency approach: Create a static image with text overlay
  tryCatch({
    # Read just the first frame
    first_frame <- image_read(gif_file)[1]
    first_frame <- image_scale(first_frame, "600x")

    # Add multiple text overlays to show the concept
    texts <- c(
      "Where do 240 million Pakistanis live?",
      "📊 DataViz by Zahid Asghar"
    )

    for (i in seq_along(texts)) {
      gravity_pos <- if (i == 1) "center" else "southeast"
      size_val <- if (i == 1) 20 else 14

      first_frame <- image_annotate(first_frame, texts[i],
                                    size = size_val,
                                    gravity = gravity_pos,
                                    color = "white",
                                    strokecolor = "black", strokewidth = 2)
    }

    # Create a simple 3-frame animation
    frame2 <- image_annotate(first_frame, "Dense clusters → jobs, markets, innovation",
                             size = 18, gravity = "north", color = "yellow",
                             strokecolor = "black", strokewidth = 2)

    frame3 <- image_annotate(first_frame, "Each dot = 100,000 people",
                             size = 18, gravity = "south", color = "cyan",
                             strokecolor = "black", strokewidth = 2)

    # Combine into simple animation
    simple_gif <- c(first_frame, frame2, frame3)
    simple_gif <- image_animate(simple_gif, fps = 1, loop = 0)

    emergency_output <- "pakistan_emergency.gif"
    image_write(simple_gif, emergency_output, quality = 50)

    cat("✓ EMERGENCY SUCCESS! Created:", emergency_output, "\n")

  }, error = function(e2) {
    cat("All approaches failed. Your GIF file may be corrupted or too large.\n")
    cat("Final error:", e2$message, "\n")
    cat("\nRecommendations:\n")
    cat("1. Check if the GIF file is valid\n")
    cat("2. Try with a smaller GIF file first\n")
    cat("3. Use online tools to compress the GIF\n")
    cat("4. Consider using a different computer with more RAM\n")
  })
})

cat("\n=== COMPLETED ===\n")
