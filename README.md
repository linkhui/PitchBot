# PitchBot - Development Guide

## Prerequisites

- Xcode 16.3 or later
- iOS 16.6 or later

## Installation Steps

1. Clone the repository
```bash
git clone https://github.com/linkhui/PitchBot
```
2. Navigate to the project directory
```bash
cd PitchBot
```

3. Open the Xcode workspace
```bash
open PitchBot.xcodeproj
```
5. Build and run the app on a simulator or a physical device

## Usage

### LLM Providers
#### MiniMax

- Chat
    - baseURL: `https://api.minimax.chat/v1/text/chatcompletion_v2`
    - model: `abab6.5s-chat`
- Text to Speech
    - baseURL: `https://api.minimax.chat/v1/t2a_v2`
    - model: `speech-02-turbo`

#### OpenAI Compatible(silliconflow)
- Chat and Evaluation
    - baseURL: `https://api.siliconflow.cn/v1/chat/completions`
    - model: `deepseek-ai/DeepSeek-V3`

### LLM Settings
- Launch the app on a simulator or a physical device
- At the left-top corner, tap on the setting button
- In the LLM Settings, you can configure the following settings:
    - select LLM Provider(MiniMax and OpenAI Compatible)
    - set the API Key

#### Chat Settings
- MiniMax or OpenAI Compatible.
- You can select the LLM Provider (MiniMax or OpenAI Compatible), and set the API Key.
- If there is no API Key, Chat will use simulation data.

#### Text to Speech Settings
- MiniMax only.
- You must set the API Key and Group ID of Minimax.
- If there is no API Key, Text to Speech will not work.
- You can mute to disable the text to speech on the top-right corner.

#### Evaluation Settings
- OpenAI Compatible only.
- You must set the API Key.
- If there is no API Key, Evaluation will use simulation data.

## License
This project is licensed under the MIT License. See the LICENSE file for details.
