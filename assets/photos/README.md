# Сюда кидай фото для галереи

Как добавить фото:
1. Закинь файл в assets/photos/ например anya_photo1.jpg (рекомендую 1080x1920, сжатый jpg ~300-500кб)
2. Открой scripts/autoload/GalleryManager.gd
3. Пропиши путь в texture_path: "res://assets/photos/anya_photo1.jpg"
4. При получении в чате вызови: GalleryManager.unlock_photo("chat_01")

Все фото автоматически появятся в галерее. Заблокированные покажут 🔒

