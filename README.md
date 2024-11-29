**KoboldR**
-
The KoboldR library is an easy and light way to integrate R with Koboldcpp, which lets you run language models locally on your own machine.
To use this R library, ensure the Koboldcpp app is installed (https://github.com/LostRuins/koboldcpp/releases/latest). 

**Setting up Koboldcpp**
-
KoboldCpp is an easy-to-use AI text-generation software for GGML and GGUF models (https://github.com/LostRuins/koboldcpp/wiki). 
To run, simply execute koboldcpp.exe.
Launching displays a GUI with configurable settings. Choose and load a GGUF model (https://github.com/LostRuins/koboldcpp?tab=readme-ov-file#Obtaining-a-GGUF-model). Recommended configurations are: uncheck “Launch Brower”, check “use FlashAttention”, and check “High Priority” in “Hardware”. 

**Installation**
-


**Usage**
-
_**General functions**_

	Get_model() #Gets the current model display name.
	
	Abort() #Aborts the currently ongoing text generation.
…

_**Text-to-text generation**_
```
Generate_text(Prompt, Memory, Genkey) #Generate text given a prompt and generation settings. 
```
- `Prompt`: The input text given to the model, which it uses to generate a response.

- `Memory`: stored information which instructs the model of the context of the prompt.

- `Genkey`: A unique genkey set by the user. Default = "KCPP2531". Used in multiple session scenario.
```
Chat() #A different text generation function that "remembers" previous conversions.
```
- WIP
```
Generate_code(Prompt) #Text generation that is specifically tuned for code instruction in R
```
- `Prompt`: The input text given to the model to generate code instruction.

_**Image-to-text generation**_
```
Image_generate_text(Prompt, Memory, Image_path, Genkey)
```
- `Prompt`: The input text given to the model, which it uses to generate a response.

- `Memory`: stored information which instructs the model of the context of the prompt.

- `Image_path`: file path of the input image

- `Genkey`: A unique genkey set by the user. Default = "KCPP2531". Used in multiple session scenario.

_**Voice-to-text generation**_

- WIP

**Application in psychological research**
-
- Example of thematic coding of emotion
```
quote <- " Well, I wanted to move up a math level, but, um, I don't think I passed the entry exam and then I kind of spent a year feeling frustrated."
Generate_text(
	quote,
	Memory = "You are conducting a thematic analysis, you code and identify negative emotions from the text. 10 negative emotions are Sadness, Anger, Upset, Frustration, Defeated, Regret, Embarassed/Ashamed, Confused, Anxiety, Disappointment. Respond a list of emotions you feel the most confident to identify. Just give me the list."
	) |> cat()
  
	# * Frustration
```
- Example of sentiment analysis 
```
quote3 <- c('I am disappointed by my grades', 'I am happy with my grades', 'I am neutral about my grades')
instruction <- "You are evaluating the sentiment of the text. Please only respond from 'positive', 'negative', or 'other'."
lapply(quote3, FUN = Generate_text, Memory = instruction) |> unlist() |> cat()

	# negative 
	# positive 
	# other
```
- Example of thematic coding of failure label
```
Generate_text(
	Prompt = science_label_dat$Quote[1],
	Memory = "What are the failure label you identify from the text? Please only answer from: Failure, Success, Neither, Both, N/A. No explanation. If there is no text, output N/A"
	) |> cat()
  
	# Failure
```
















