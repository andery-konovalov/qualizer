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
    char extraParamSize[2];
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
	
	const int buffer_len = 176400 * 6;
	
	uint8_t buffer[buffer_len];
	//auto read_cnt = in_file.read(reinterpret_cast< char * >( buffer ), buffer_len ).gcount( );
	
    uint32_t buffer_ptr = 0;
    auto lmbd = [&buffer, &buffer_len, &buffer_ptr, &header, &in_file]( void **data_, uint32_t data_size, float sampleTime )
    {
		//cout << "Sample time: " << sampleTime << endl;
		if( sampleTime * 4 != buffer_ptr )
		{
//			cout << "!!!!!!" << endl;
		}
		auto read_cnt = in_file.read(reinterpret_cast< char * >( *data_ ), data_size ).gcount( );
//		memset(data_2, 0, data_size_2);
		//memset(data, 0, data_size);
/*
		uint32_t d_size = (buffer_len - buffer_ptr > data_size) ? data_size : buffer_len - buffer_ptr;
		memcpy( data, &buffer[buffer_ptr], d_size );
		memcpy( data_2, &buffer[buffer_ptr], d_size );
		buffer_ptr += d_size;
*/
/*
		void *data = *data_;
		for(uint32_t i = 0,j = buffer_ptr; j < buffer_len / 2 && i < data_size / 2 ;i+=1, j+=1, buffer_ptr += 1)
		{
			//uint8_t byte = ((uint8_t *)buffer)[j];
			((uint16_t *)data)[i] = (((uint16_t *)buffer)[j]);
//			((uint8_t *)data)[i + 1] = ((uint8_t *)buffer)[j];
			
			//((uint16_t *)data_2)[i] = ((uint16_t *)buffer)[j];
			//((uint16_t *)data)[i + 1] = ((uint16_t *)buffer)[j + 1];
		}
*/
    };
    
    AudioUnitWorker::initAudioUnit( lmbd );
    
   // AVAudioUnit
    return 0;
}
