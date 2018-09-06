//
//  main.cpp
//  wav_dumper
//
//  Created by Konovalov, Andrii on 16.08.18.
//  Copyright © 2018 Konovalov, Andrii. All rights reserved.
//

#include <iostream>
#include <fstream>
#include <math.h>

#include "AudioUnitWorker.hpp"

using namespace std;

#pragma pack(1)
// Структура, описывающая заголовок WAV файла.
struct WAVHEADER
{
    // WAV-формат начинается с RIFF-заголовка:
    
    // Содержит символы "RIFF" в ASCII кодировке
    // (0x52494646 в big-endian представлении)
    char chunkId[4];
    
    // 36 + subchunk2Size, или более точно:
    // 4 + (8 + subchunk1Size) + (8 + subchunk2Size)
    // Это оставшийся размер цепочки, начиная с этой позиции.
    // Иначе говоря, это размер файла - 8, то есть,
    // исключены поля chunkId и chunkSize.
    uint32_t chunkSize;
    
    // Содержит символы "WAVE"
    // (0x57415645 в big-endian представлении)
    char format[4];
    
    // Формат "WAVE" состоит из двух подцепочек: "fmt " и "data":
    // Подцепочка "fmt " описывает формат звуковых данных:
    
    // Содержит символы "fmt "
    // (0x666d7420 в big-endian представлении)
    char subchunk1Id[4];
    
    // 16 для формата PCM.
    // Это оставшийся размер подцепочки, начиная с этой позиции.
    uint32_t subchunk1Size;
    
    // Аудио формат, полный список можно получить здесь http://audiocoding.ru/wav_formats.txt
    // Для PCM = 1 (то есть, Линейное квантование).
    // Значения, отличающиеся от 1, обозначают некоторый формат сжатия.
    uint16_t audioFormat;
    
    // Количество каналов. Моно = 1, Стерео = 2 и т.д.
    uint16_t numChannels;
    
    // Частота дискретизации. 8000 Гц, 44100 Гц и т.д.
    uint32_t sampleRate;
    
    // sampleRate * numChannels * bitsPerSample/8
    uint32_t byteRate;
    
    // numChannels * bitsPerSample/8
    // Количество байт для одного сэмпла, включая все каналы.
    uint16_t blockAlign;
    
    // Так называемая "глубиная" или точность звучания. 8 бит, 16 бит и т.д.
    uint16_t bitsPerSample;
    char should_be_fixed[2];
    // Подцепочка "data" содержит аудио-данные и их размер.
    
    // Содержит символы "data"
    // (0x64617461 в big-endian представлении)
    char subchunk2Id[4];
    
    // numSamples * numChannels * bitsPerSample/8
    // Количество байт в области данных.
    uint32_t subchunk2Size;
    
    // Далее следуют непосредственно Wav данные.
};
#pragma pack()
int main(int argc, const char* argv[])
{
    if ( argc < 2 )
    {
        cout << "Invalid arguments" << endl;
        return -1;
    }
    
    ifstream in_file( argv[1] );
    if( !in_file.is_open() )
    {
        cout << "Could not open the file: " << argv[1] << endl;
        return -1;
    }
    
    WAVHEADER header;
    
    auto bytes_processed = in_file.read( reinterpret_cast< char * >( &header ), sizeof( WAVHEADER ) ).gcount( );
    if ( bytes_processed != sizeof( WAVHEADER ) )
    {
        return -1;
    }
    
    // Выводим полученные данные
    cout << "Sample rate: " << header.sampleRate << endl
         << "Channels: " << header.numChannels << endl
         << "Bits per sample: " << header.bitsPerSample << endl
         << "Byte rate: " << header.byteRate << endl
         << "Audio format: " << header.audioFormat << endl
         << "Chunk size: " << header.chunkSize << endl
         << "BlockAlign: " << header.blockAlign << endl
         << "Data size: " << header.subchunk2Size << endl;

    // Посчитаем длительность воспроизведения в секундах
    float fDurationSeconds = 1.f * header.subchunk2Size / (header.bitsPerSample / 8) / header.numChannels / header.sampleRate;
    int iDurationMinutes = (int)floor(fDurationSeconds) / 60;
    fDurationSeconds = fDurationSeconds - (iDurationMinutes * 60);
    cout << "Duration: " << iDurationMinutes << ':' << fDurationSeconds << endl;
    
    uint32_t total_byte_processed = 0;
    auto lmbd = [&in_file, &total_byte_processed, &header]( void *data, uint32_t data_size )
    {
        uint32_t buffer[512];
        uint32_t buffer_ptr = 0;

        while( buffer_ptr < data_size/2 )
        {
            auto read_cnt = in_file.read(reinterpret_cast< char * >( buffer ), 512 * sizeof( uint32_t ) ).gcount( );
            if( read_cnt > 0 )
            {
                for( size_t i = 0; i < read_cnt / 4; i ++ )
                {
                    ((uint16_t *)data)[buffer_ptr ++] = *((uint16_t *)&buffer[i]);
                    
                }
            }
            else
            {
                break;
            }
        }
      
    };
    
    AudioUnitWorker::initAudioUnit( lmbd );
    
   // AVAudioUnit
    return 0;
}
