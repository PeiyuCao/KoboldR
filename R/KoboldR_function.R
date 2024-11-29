library(httr)
library(jsonlite)
library(tidyverse)
library(readxl)
library(psych)
library(RCurl)
library(magick)
library(base64enc)

#pre-process prompt to instruct the LLM
string_preprocess_text <- function(input_string) {
  # Prepend and append text to the original string
  output_string <- paste("\n### Instruction:\n", 
                         input_string, 
                         "\n### Response:\n", 
                         sep="")
  return(output_string)
}


#generate json to be sent via API
generate_quiry_json_text <- function(
    Prompt, 
    Memory, 
    Genkey 
){
  json_data <- list(
    n = 1, 
    max_context_length = 16384, 
    max_length = 1000, 
    rep_pen = 1.07, 
    temperature = 0.7, 
    top_p = 0.92, 
    top_k = 100, 
    top_a = 0, 
    typical = 1, 
    tfs = 1, 
    rep_pen_range = 360, 
    rep_pen_slope = 0.7, 
    sampler_order = c(6, 0, 1, 3, 4, 2, 5),
    memory = Memory,
    trim_stop = TRUE,
    genkey = Genkey,
    min_p = 0, 
    dynatemp_range = 0, 
    dynatemp_exponent = 1, 
    smoothing_factor = 0, 
    banned_tokens = c(), 
    render_special = FALSE, 
    presence_penalty = 0, 
    logit_bias = list(),
    prompt = Prompt,
    quiet = TRUE, 
    stop_sequence = c("### Instruction:", "### Response:"), 
    use_default_badwordsids = FALSE, 
    bypass_eos = FALSE
  )
  quiry_json <- toJSON(json_data, auto_unbox = TRUE, pretty = TRUE)
  return(quiry_json)
}


#pre-process prompt to instruct the LLM
string_preprocess_image <- function(input_string) {
  # Prepend and append text to the original string
  output_string <- paste("\n(Attached Image)\n\n### Instruction:\n", 
                         input_string, 
                         "\n### Response:\n", 
                         sep="")
  return(output_string)
}

image_preprocess <- function(image_path) {
  # Replace this with your actual image path
  img <- image_read(image_path)
  
  # Resize the image to fit within 512x512 while preserving aspect ratio
  img_resized <- image_resize(img, "512x512>")
  
  # Get current dimensions
  info <- image_info(img_resized)
  width <- info$width
  height <- info$height
  
  # Calculate padding to center the image
  x_offset <- max(0, (512 - width) / 2)
  y_offset <- max(0, (512 - height) / 2)
  
  # Add black background and extend to exact 180x180, centering the original image
  img_final <- image_background(img_resized, "black", flatten = TRUE) %>%
    image_extent(geometry = paste(512, 512, x_offset, y_offset, sep = "x"))
  
  # Optionally, write the image to a file or use it in your application
  image_write(img_final, 
              "resized_image.jpeg", 
              format = 'jpeg', 
              depth = 16, 
              quality = 40,
              compression = 'JPEG'
  )  
  
  image_encoded <- as.character(base64encode("resized_image.jpeg"))
  
  return(image_encoded)
}



generate_quiry_json_image <- function(
    Prompt, 
    Memory,
    Image,
    Genkey 
){
  json_data <- list(
    n = 1, 
    max_context_length = 16384, 
    max_length = 1000, 
    rep_pen = 1.07, 
    temperature = 0.7, 
    top_p = 0.92, 
    top_k = 100, 
    top_a = 0, 
    typical = 1, 
    tfs = 1, 
    rep_pen_range = 360, 
    rep_pen_slope = 0.7, 
    sampler_order = c(6, 0, 1, 3, 4, 2, 5),
    memory = Memory,
    trim_stop = TRUE,
    images = list(Image),
    genkey = Genkey,
    min_p = 0, 
    dynatemp_range = 0, 
    dynatemp_exponent = 1, 
    smoothing_factor = 0, 
    banned_tokens = c(), 
    render_special = FALSE, 
    presence_penalty = 0, 
    logit_bias = list(),
    prompt = Prompt,
    quiet = TRUE, 
    stop_sequence = c("### Instruction:", "### Response:"), 
    use_default_badwordsids = FALSE, 
    bypass_eos = FALSE
  )
  quiry_json <- toJSON(json_data, auto_unbox = TRUE, pretty = TRUE)
  return(quiry_json)
}



#process returned json to a string
output_as_string <- function(output_json) {
  library(jsonlite)  # Ensure jsonlite or similar library is loaded for fromJSON()
  
  sse_data <- rawToChar(output_json$content)
  # Normalize newlines and split the data into lines
  lines <- strsplit(gsub("\r\n|\r|\n", "\n", sse_data), "\n")[[1]]
  
  # Initialize an empty string to hold the final message
  final_message <- ""
  
  # Loop through each line
  for (line in lines) {
    # Check if the line contains "data:" using a regex that allows optional whitespace
    if (grepl("^data:\\s*", line)) {
      # Extract JSON part from the line removing "data:" prefix and any leading spaces
      json_data <- gsub("^data:\\s*", "", line)
      
      # Try to parse the JSON data and catch any errors
      tryCatch({
        parsed_data <- fromJSON(json_data)
        
        # Concatenate the token to the final message
        if (!is.null(parsed_data$token)) {
          # Replace literal "\n" with actual new lines in token
          parsed_token <- gsub("\\\\n", "\n", parsed_data$token)
          final_message <- paste0(final_message, parsed_token)
        }
        
        # Check if the finish reason is "stop"
        if (parsed_data$finish_reason == "stop") {
          break
        }
      }, error = function(e) {
        cat("Error in parsing JSON: ", e$message, "\n")
      })
    }
  }
  
  # Return the final message with actual new lines
  return(final_message)
}


#' A Text Generation Function
#'
#' This function allows you to generate text given a prompt and generation settings.
#' @param Prompt The input text given to the model to generate a response.
#' @param Memory Context given to the model in text generation.
#' @param Genkey A unique genkey of each generation session, used in multiple session scenario. Default to "KCPP2531". 
#' @keywords text, generation
#' @export
#' @examples
#' greeting <- "Hi there"
#' Generate_text(greeting, Memory = '') |> cat()

Generate_text <- function(
    Prompt, 
    Memory,
    Genkey = "KCPP2531")
{
  output <- POST('http://localhost:5001/api/extra/generate/stream',
                 body = generate_quiry_json_text(string_preprocess_text(Prompt), 
                                                 Memory, 
                                                 Genkey),
                 encode = "json") 
  output <- output_as_string(output) 
  return(output)
}

#' A Code Instruction Function
#'
#' This function is specifically tuned for code instruction in R.
#' @param Prompt The input text given to the model to generate code instruction.
#' @keywords text, code, instruction
#' @export
#' @examples
#' program <- 'Could you write a piece of R code that defines a function, which gives the mean and sd of a data frame?'
#' Generate_code(program)

Generate_code <- function(Prompt) {
  output <- Generate_text(Prompt, 
                          Memory = "You are a code instructor. Teach me how to write codes",
                          Genkey = "KCPP2531")
  cat(output)
  }
# code <- str_extract(output, "(?s)(?<=```).*?(?=```)")
# lines <- strsplit(code, "\n")[[1]]
# lines <- lines[-1]
# new_string <- paste(lines, collapse = "\n")
# eval(parse(text = new_string))



#' An Image-to-Text Generation Function
#'
#' This function allows you to generate text given a prompt, an image, and generation settings.
#' @param Prompt The input text given to the model to generate a response.
#' @param Memory Context given to the model in text generation.
#' @param Image_path file path of the input image
#' @param Genkey A unique genkey of each generation session, used in multiple session scenario. Default to "KCPP2531". 
#' @keywords text, image, generation
#' @export
#' @examples
#' Image_generate_text(
#'           'Could you describe the image?', 
#'           Memory = '', 
#'           'Cats_purring.png'
#'           ) |> cat()

Image_generate_text <- function(
    Prompt, 
    Memory,
    Image_path,
    Genkey = "KCPP2531") 
{
  output <- POST('http://localhost:5001/api/extra/generate/stream',
                 body = generate_quiry_json_image(string_preprocess_image(Prompt), 
                                                  Memory,
                                                  image_preprocess(Image_path),
                                                  Genkey),
                 encode = "json") 
  output <- output_as_string(output) 
  return(output)
}



#' A Get Model Function 
#'
#' This function returns the current model display name.
#' @param 
#' @keywords model
#' @export
#' @examples
#' Get_model()

Get_model <- function() {
  response <- GET('http://localhost:5001/api/v1/model')
  output <- ?content(response, "parsed", type = "application/json")
  output |> unlist() |> cat()
}


#' An Abort Function 
#'
#' This function aborts the currently ongoing text generation.
#' @param 
#' @keywords abort
#' @export
#' @examples
#' Abort()

Abort <- function() {
  response <- POST('http://localhost:5001/api/extra/abort', 
                   body = "genkey = KCPP2531",
                   encode = "json")
  if (response$status_code == 200){
    print("Generation Aborted")
  }
  else {
    print("Request failed")
  }
}

