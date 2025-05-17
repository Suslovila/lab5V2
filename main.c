// lab5.c — BMP to grayscale converter (C-only, no ASM)
// Исправленная версия

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#pragma pack(push,1)
typedef struct {
    uint16_t bfType;        // 'BM' == 0x4D42
    uint32_t bfSize;        // размер файла
    uint16_t bfReserved1;
    uint16_t bfReserved2;
    uint32_t bfOffBits;     // смещение до пикселей
} BITMAPFILEHEADER;
#pragma pack(pop)

#pragma pack(push,1)
typedef struct {
    uint32_t biSize;          // должен быть 40
    int32_t  biWidth;         // ширина
    int32_t  biHeight;        // высота (может быть отрицательной)
    uint16_t biPlanes;        // =1
    uint16_t biBitCount;      // =24
    uint32_t biCompression;   // =0 (BI_RGB)
    uint32_t biSizeImage;     // размер растровых данных
    int32_t  biXPelsPerMeter;
    int32_t  biYPelsPerMeter;
    uint32_t biClrUsed;
    uint32_t biClrImportant;
} BITMAPINFOHEADER;
#pragma pack(pop)


extern void grayscale_asm(uint8_t *data, int32_t width, int32_t height);


static void grayscale(uint8_t *data, int32_t width, int32_t height) {
    // каждая строка — выровнена до 4 байтов
    size_t row_size = (width * 3 + 3) & ~3u;
    for (int32_t y = 0; y < height; ++y) {
        uint8_t *row = data + (size_t)y * row_size;
        for (int32_t x = 0; x < width; ++x) {
            uint8_t *p = row + x * 3;  // B, G, R
            float rf = p[2], gf = p[1], bf = p[0];
            float grayf = 0.299f * rf + 0.587f * gf + 0.114f * bf;
            uint8_t gray = (uint8_t)(grayf + 0.5f);
            p[0] = p[1] = p[2] = gray;
        }
    }
}

int main(int argc, char **argv) {
    if (argc != 3 && argc != 4) {
        fprintf(stderr, "Usage: %s <input.bmp> <output.bmp>\n", argv[0]);
        return EXIT_FAILURE;
    }

    const char *infile  = argv[1];
    const char *outfile = argv[2];

    FILE *f = fopen(infile, "rb");
    if (!f) {
        fprintf(stderr, "Error: cannot open input file \"%s\"\n", infile);
        return EXIT_FAILURE;
    }

    BITMAPFILEHEADER bfh;
    if (fread(&bfh, sizeof bfh, 1, f) != 1) {
        fprintf(stderr, "Error: failed to read BITMAPFILEHEADER\n");
        fclose(f);
        return EXIT_FAILURE;
    }
    if (bfh.bfType != 0x4D42) {
        fprintf(stderr, "Error: \"%s\" is not a BMP file (bfType=0x%04X)\n",
                infile, bfh.bfType);
        fclose(f);
        return EXIT_FAILURE;
    }

    BITMAPINFOHEADER bih;
    if (fread(&bih, sizeof bih, 1, f) != 1) {
        fprintf(stderr, "Error: failed to read BITMAPINFOHEADER\n");
        fclose(f);
        return EXIT_FAILURE;
    }
    if (bih.biSize     != 40  ||
        bih.biPlanes   != 1   ||
        bih.biBitCount != 24  ||
        bih.biCompression != 0)
    {
        fprintf(stderr,
                "Error: unsupported BMP format (biSize=%u, planes=%u, bpp=%u, comp=%u)\n",
                bih.biSize, bih.biPlanes, bih.biBitCount, bih.biCompression);
        fclose(f);
        return EXIT_FAILURE;
    }

    int32_t width  = bih.biWidth;
    int32_t height = bih.biHeight > 0 ? bih.biHeight : -bih.biHeight;
    size_t row_size = (width * 3 + 3) & ~3u;
    size_t img_size = row_size * (size_t)height;

    uint8_t *pixels = malloc(img_size);
    if (!pixels) {
        fprintf(stderr, "Error: out of memory allocating %zu bytes\n", img_size);
        fclose(f);
        return EXIT_FAILURE;
    }

    if (fseek(f, bfh.bfOffBits, SEEK_SET) != 0) {
        fprintf(stderr, "Error: fseek to pixel data failed\n");
        free(pixels);
        fclose(f);
        return EXIT_FAILURE;
    }
    if (fread(pixels, 1, img_size, f) != img_size) {
        fprintf(stderr, "Error: failed to read pixel data\n");
        free(pixels);
        fclose(f);
        return EXIT_FAILURE;
    }
    fclose(f);
    int use_c = (argc == 4);
    if (use_c)
        grayscale(pixels, width, height);
    else
        grayscale_asm(pixels, width, height);

    // Обновляем поля размеров
    bih.biSizeImage = (uint32_t)img_size;
    bfh.bfSize      = bfh.bfOffBits + bih.biSizeImage;

    f = fopen(outfile, "wb");
    if (!f) {
        fprintf(stderr, "Error: cannot open output file \"%s\"\n", outfile);
        free(pixels);
        return EXIT_FAILURE;
    }
    if (fwrite(&bfh, sizeof bfh, 1, f) != 1 ||
        fwrite(&bih, sizeof bih, 1, f) != 1 ||
        fwrite(pixels, 1, img_size, f) != img_size)
    {
        fprintf(stderr, "Error: failed to write BMP data\n");
        free(pixels);
        fclose(f);
        return EXIT_FAILURE;
    }
    fclose(f);
    free(pixels);

    printf("Converted \"%s\" to \"%s\" (%d x %d pixels)\n",
           infile, outfile, width, height);

    return EXIT_SUCCESS;
}
