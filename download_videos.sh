#!/bin/bash

# Функция для установки зависимостей
install_dependencies() {
    local dependencies=("yt-dlp" "jq" "curl" "grep")
    local missing_deps=()
    local brew_installed=false

    # Проверяем, установлен ли Homebrew
    if ! command -v brew &> /dev/null; then
        echo "Homebrew не установлен. Установите его с помощью:"
        echo '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
        exit 1
    fi

    # Проверяем каждую зависимость
    for dep in "${dependencies[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done

    # Если есть отсутствующие зависимости, устанавливаем их
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo "Устанавливаем отсутствующие зависимости..."
        for dep in "${missing_deps[@]}"; do
            echo "Установка $dep..."
            brew install "$dep"
            if [ $? -ne 0 ]; then
                echo "Ошибка при установке $dep"
                exit 1
            fi
        done
        echo "Все зависимости успешно установлены"
    else
        echo "Все необходимые зависимости уже установлены"
    fi
}

# Функция для проверки зависимостей
check_dependencies() {
    local dependencies=("yt-dlp" "jq" "curl" "grep")
    local missing_deps=()

    for dep in "${dependencies[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done

    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo "Отсутствуют следующие зависимости:"
        for dep in "${missing_deps[@]}"; do
            echo "- $dep"
        done
        echo "Установить зависимости? (y/n)"
        read -r answer
        if [[ $answer =~ ^[Yy]$ ]]; then
            install_dependencies
        else
            echo "Установите зависимости вручную:"
            echo "brew install ${missing_deps[*]}"
            exit 1
        fi
    fi
}

# Функция для создания директории для загрузок
create_download_dir() {
    local download_dir="downloads"
    if [ ! -d "$download_dir" ]; then
        mkdir -p "$download_dir"
        echo "Создана директория для загрузок: $download_dir"
    fi
}

# Функция для извлечения ID видео из URL Vimeo
extract_vimeo_id() {
    local url="$1"
    local video_id=""
    
    # Проверяем разные форматы URL Vimeo
    if [[ $url == *"player.vimeo.com/video/"* ]]; then
        video_id=$(echo "$url" | grep -oE 'video/[0-9]+' | cut -d'/' -f2)
    elif [[ $url == *"vimeo.com/"* ]]; then
        video_id=$(echo "$url" | grep -oE 'vimeo.com/[0-9]+' | cut -d'/' -f2)
    fi
    
    if [ -z "$video_id" ]; then
        echo "Не удалось извлечь ID видео из URL"
        return 1
    fi
    
    echo "$video_id"
}

# Функция для извлечения реального URL из Vimeo
extract_vimeo_url() {
    local url="$1"
    local video_id=""
    
    # Если это blob URL
    if [[ $url == blob:* ]]; then
        video_id=$(echo "$url" | grep -oE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}')
    else
        # Если это обычный URL Vimeo
        video_id=$(extract_vimeo_id "$url")
    fi
    
    if [ -z "$video_id" ]; then
        echo "Не удалось извлечь ID видео из URL"
        return 1
    fi
    
    # Получаем информацию о видео через API Vimeo
    local api_url="https://player.vimeo.com/video/$video_id/config"
    local api_response=$(curl -s -H "Referer: https://player.vimeo.com/" \
        -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36" \
        -H "Accept: application/json" \
        -H "Origin: https://player.vimeo.com" \
        "$api_url")
    
    if [ -z "$api_response" ]; then
        echo "Не удалось получить данные от API Vimeo"
        return 1
    fi
    
    # Сохраняем ответ API для отладки
    echo "$api_response" > "vimeo_api_response_$video_id.json"
    
    # Извлекаем URL видео из ответа API
    local video_url=""
    
    # Пробуем найти прогрессивное видео
    video_url=$(echo "$api_response" | jq -r '.request.files.progressive[] | select(.quality=="1080p" or .quality=="720p" or .quality=="540p") | .url' 2>/dev/null)
    
    if [ -z "$video_url" ]; then
        # Если не нашли прогрессивное видео, пробуем найти HLS
        video_url=$(echo "$api_response" | jq -r '.request.files.hls.cdns[].url' 2>/dev/null)
    fi
    
    if [ -z "$video_url" ]; then
        # Если не нашли HLS, пробуем найти DASH
        video_url=$(echo "$api_response" | jq -r '.request.files.dash.cdns[].url' 2>/dev/null)
    fi
    
    if [ -z "$video_url" ]; then
        # Если ничего не нашли, пробуем найти любой доступный URL
        video_url=$(echo "$api_response" | jq -r '.. | select(type == "string" and contains("vimeocdn.com"))' 2>/dev/null | head -n 1)
    fi
    
    if [ -z "$video_url" ]; then
        echo "Не удалось найти URL видео"
        return 1
    fi
    
    echo "$video_url"
}

# Функция для извлечения URL из HTML iframe
extract_url_from_iframe() {
    local iframe_html="$1"
    local url=""
    
    # Извлекаем URL из атрибута src
    url=$(echo "$iframe_html" | grep -oE 'src="[^"]+"' | cut -d'"' -f2)
    
    if [ -z "$url" ]; then
        echo "Не удалось извлечь URL из iframe"
        return 1
    fi
    
    # Декодируем HTML-сущности
    url=$(echo "$url" | sed 's/&amp;/\&/g')
    
    echo "$url"
}

# Функция для скачивания видео
download_video() {
    local url="$1"
    local embed_url="$2"
    local download_dir="downloads"
    local success=false
    
    echo "Скачиваем: $url"
    if [ -n "$embed_url" ]; then
        echo "URL страницы встраивания: $embed_url"
    fi
    
    # Проверяем, является ли входной параметр файлом
    if [ -f "$url" ]; then
        echo "Обнаружен файл, читаем содержимое..."
        local iframe_content=$(cat "$url")
        if [[ $iframe_content == *"<iframe"* ]]; then
            echo "Обнаружен HTML iframe, извлекаем URL..."
            local extracted_url=$(extract_url_from_iframe "$iframe_content")
            
            if [ $? -eq 0 ]; then
                echo "Извлечен URL: $extracted_url"
                url="$extracted_url"
                # Если это iframe и не указан URL страницы встраивания, используем URL курса
                if [ -z "$embed_url" ]; then
                    embed_url="https://online.cnmstudent.com/course/view.php?id=108"
                fi
            fi
        fi
    # Проверяем, является ли входной параметр HTML iframe
    elif [[ $url == *"<iframe"* ]]; then
        echo "Обнаружен HTML iframe, извлекаем URL..."
        local extracted_url=$(extract_url_from_iframe "$url")
        
        if [ $? -eq 0 ]; then
            echo "Извлечен URL: $extracted_url"
            url="$extracted_url"
            # Если это iframe и не указан URL страницы встраивания, используем URL курса
            if [ -z "$embed_url" ]; then
                embed_url="https://online.cnmstudent.com/course/view.php?id=108"
            fi
        fi
    fi
    
    # Создаем временный файл для cookies в формате Netscape
    local cookie_file=$(mktemp)
    # Добавляем заголовок Netscape cookies file
    echo "# Netscape HTTP Cookie File" > "$cookie_file"
    echo "# https://curl.se/docs/http-cookies.html" >> "$cookie_file"
    echo "# This file was generated by download_videos.sh" >> "$cookie_file"
    echo "#" >> "$cookie_file"
    
    # Добавляем cookies в правильном формате
    # Формат: domain flag path secure expiration name value
    echo ".online.cnmstudent.com\tTRUE\t/\tFALSE\t0\tMoodleSession\t" >> "$cookie_file"
    echo ".online.cnmstudent.com\tTRUE\t/\tFALSE\t0\tloglevel\tWARN" >> "$cookie_file"
    echo ".online.cnmstudent.com\tTRUE\t/\tFALSE\t0\tmdl-tiles-course-108-user-16304-lastSecId\t23" >> "$cookie_file"
    echo ".online.cnmstudent.com\tTRUE\t/\tFALSE\t0\tscribe_extension_state\t{\"id\":\"okfkdaglfjjjfefdcppliegebpoegaii\",\"version\":\"2.27.0\",\"lastHeard\":1743937849142}" >> "$cookie_file"
    
    # Для Vimeo используем специальные параметры
    if [[ $url == *"vimeo.com"* ]]; then
        echo "Обнаружен URL Vimeo, используем специальные параметры..."
        
        # Если не указан URL страницы встраивания, используем URL курса
        if [ -z "$embed_url" ]; then
            embed_url="https://online.cnmstudent.com/course/view.php?id=108"
            echo "Используем URL страницы встраивания по умолчанию: $embed_url"
        fi
        
        # Сначала получаем список доступных форматов
        echo "Получаем список доступных форматов..."
        yt-dlp -F "$url" --cookies "$cookie_file" --cookies-from-browser chrome --referer "$embed_url"
        
        # Формируем команду для скачивания с более гибким выбором формата
        local cmd="yt-dlp -o \"$download_dir/%(title)s.%(ext)s\" \
            --format \"bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio/best\" \
            --add-header \"Referer: $embed_url\" \
            --add-header \"User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36\" \
            --add-header \"Origin: https://online.cnmstudent.com\" \
            --add-header \"Accept: */*\" \
            --add-header \"Accept-Language: en-US,en;q=0.9\" \
            --add-header \"Accept-Encoding: gzip, deflate, br\" \
            --add-header \"Connection: keep-alive\" \
            --add-header \"Sec-Fetch-Dest: empty\" \
            --add-header \"Sec-Fetch-Mode: cors\" \
            --add-header \"Sec-Fetch-Site: cross-site\" \
            --cookies \"$cookie_file\" \
            --cookies-from-browser chrome \
            --no-check-certificates \
            --no-warnings \
            --ignore-errors \
            --retries 10 \
            --fragment-retries 10 \
            --skip-unavailable-fragments \
            --extractor-args \"vimeo:referrer=$embed_url\" \
            --merge-output-format mp4 \
            --prefer-free-formats \
            --write-subs \
            --write-auto-subs \
            --embed-subs \
            --embed-thumbnail \
            --embed-metadata"
        
        # Добавляем URL видео и выполняем команду
        cmd="$cmd \"$url\""
        if eval "$cmd"; then
            success=true
        fi
    else
        # Для других источников используем стандартные параметры с cookies
        if yt-dlp -o "$download_dir/%(title)s.%(ext)s" \
            --format "best" \
            --cookies "$cookie_file" \
            --cookies-from-browser chrome \
            "$url"; then
            success=true
        fi
    fi
    
    # Удаляем временный файл cookies
    rm -f "$cookie_file"
    
    if [ "$success" = true ]; then
        echo "Успешно скачано: $url"
        return 0
    else
        echo "Ошибка при скачивании: $url"
        return 1
    fi
}

# Функция для скачивания видео по URL
download_single_video() {
    local url="$1"
    local embed_url="$2"
    
    if [ -z "$url" ]; then
        echo "URL не указан"
        return 1
    fi
    
    check_dependencies
    create_download_dir
    download_video "$url" "$embed_url"
}

# Основная функция для обработки JSON файлов
process_json_files() {
    local json_files=($(find . -name "*.json" -type f))
    
    if [ ${#json_files[@]} -eq 0 ]; then
        echo "JSON файлы не найдены в текущей директории"
        return 1
    fi
    
    echo "Найдено JSON файлов: ${#json_files[@]}"
    
    for json_file in "${json_files[@]}"; do
        echo "Обработка файла: $json_file"
        
        local urls=($(jq -r '.options.playlist[].sources.hls.src // empty' "$json_file" 2>/dev/null | grep -E '^https?://'))
        
        if [ ${#urls[@]} -ne 0 ]; then
            for url in "${urls[@]}"; do
                download_video "$url" ""
            done
        else
            echo "В файле $json_file не найдено видео"
        fi
    done
}

# Обработка аргументов командной строки
if [ $# -eq 0 ]; then
    # Если аргументов нет, обрабатываем JSON файлы
    check_dependencies
    create_download_dir
    process_json_files
else
    # Если есть аргументы, скачиваем указанное видео
    check_dependencies
    create_download_dir
    download_single_video "$1" "$2"
fi 