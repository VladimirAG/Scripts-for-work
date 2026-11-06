import cv2
import os
from pathlib import Path

def convert_16bit_to_8bit_bmp(input_root, output_root):
    input_path = Path(input_root)
    output_path = Path(output_root)
    
    # Рекурсивный обход всех файлов в исходной директории
    for file_path in input_path.rglob('*.png'):
        rel_path = file_path.relative_to(input_path) # относительный путь, чтобы сохранить структуру папок     
        dst_file_path = output_path / rel_path.with_suffix('.bmp') # путь для сохранения, c расширением на .bmp
        dst_file_path.parent.mkdir(parents=True, exist_ok=True) # создание целевой папки, если её не существует
        
        # Чтение изображения 16-бит
        # Флаг IMREAD_UNCHANGED важен, иначе OpenCV обрежет данные до 8 бит при чтении
        img_16bit = cv2.imread(str(file_path), cv2.IMREAD_UNCHANGED)
        
        if img_16bit is None:
            print("Ошибка чтения: {file_path}")
            continue
            
        # Нормализация и конвертация в 8 бит
        img_8bit = cv2.normalize(
            img_16bit, 
            None, 
            alpha=0, 
            beta=255, 
            norm_type=cv2.NORM_MINMAX, 
            dtype=cv2.CV_8U
        )
        
        cv2.imwrite(str(dst_file_path), img_8bit)
        
    print("Результаты сохранены в: {output_path}")

if __name__ == "__main__":
    SOURCE_DIR = r'C:\Users\user\Desktop\For_Conversion' # Папка, где лежат исходные .png (с вложенными папками)
    DESTINATION_DIR = r'C:\Users\user\Desktop\Conversed' # Папка, куда сохранятся новые .bmp
    
    convert_16bit_to_8bit_bmp(SOURCE_DIR, DESTINATION_DIR)