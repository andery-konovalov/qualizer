//
//  AudioUnitWorker.cpp
//  wav_dumper
//
//  Created by Konovalov, Andrii on 21.08.18.
//  Copyright © 2018 Konovalov, Andrii. All rights reserved.
//

#include <AudioToolbox/AudioToolbox.h>
#include <AudioUnit/AudioUnit.h>
#include <AudioUnit/AUComponent.h>
#include <AudioUnit/AudioComponent.h>
#include <AudioToolBox/AudioUnitProperties.h>
#include <AVFoundation/AVFoundation.h>
#include <CoreAudio/CoreAudio.h>

#include <iostream>

using namespace std;


#include "AudioUnitWorker.hpp"

void dumpAUParameter( AUParameter *param )
{
	NSLog( @"DisplayName: %@", param.displayName );
	NSLog( @"UnitName: %@", param.unitName );
	NSLog( @"Identifier: %@", param.identifier );
	NSLog( @"Max value: %f", param.maxValue );
	NSLog( @"Mim value: %f", param.minValue );
	NSLog( @"Value: %f", param.value );
	NSLog( @"Unit: %d", param.unit );

	for( NSString *str in param.valueStrings )
	{
		NSLog( @"ValueString %@", str );
	}
}

void dumpStreamFormatDescription( const AudioStreamBasicDescription *streamDescription )
{
	NSLog( @"-----" );
	NSLog( @"Sumple rate %f", streamDescription->mSampleRate );
    NSLog( @"Bits per channel %d", streamDescription->mBitsPerChannel );
    NSLog( @"Bytes per frame %d", streamDescription->mBytesPerFrame );
    NSLog( @"Bytes per packet %d", streamDescription->mBytesPerPacket );
    NSLog( @"ChannelsPerFrame %d", streamDescription->mChannelsPerFrame );
    NSLog( @"Frames per packet %d", streamDescription->mFramesPerPacket );
	NSLog( @"FormatID %c%c%c%c", ((const char *)&streamDescription->mFormatID)[0],
		  ((const char *)&streamDescription->mFormatID)[1],
		  ((const char *)&streamDescription->mFormatID)[2],
	((const char *)&streamDescription->mFormatID)[3]);
}


void AudioUnitWorker::initAudioUnit( std::function<void(void *data, uint32_t data_size, void *data_2, uint32_t data_size_2 )> render_callback )
{
    //AudioUnit audioUnit;
    AudioComponentDescription desc = {0};
    
    //There are several Different types of AudioUnits.
    //Some audio units serve as Outputs, Mixers, or DSP
    //units. See AUComponent.h for listing
    
    desc.componentType = kAudioUnitType_Output;
    
    //Every Component has a subType, which will give a clearer picture
    //of what this components function will be.
    
    desc.componentSubType = kAudioUnitSubType_DefaultOutput;
    //desc.componentSubType = kAudioUnitSubType_HALOutput;

    //All AudioUnits in AUComponent.h must use
    //"kAudioUnitManufacturer_Apple" as the Manufacturer
    
    desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    
    UInt32 componentsCount = AudioComponentCount(&desc);
    cout << "Audio components count: '" << componentsCount << "'" << endl;
    //Finds a component that meets the desc spec's
    AudioComponent component = nullptr;
    for(UInt32 i = 0;i < componentsCount; i ++)
    {
        component = AudioComponentFindNext(component, &desc);
        if (component == nullptr) exit (-1);
        CFStringRef cfStr;
        AudioComponentCopyName(component, &cfStr);
        cout << "Device name: '" << CFStringGetCStringPtr(cfStr, kCFStringEncodingUTF8) << '\'' << endl;
    }
    
    NSError *error = nil;
	__block AVAudioUnit *avUnit = nil;
	[AVAudioUnit instantiateWithComponentDescription:desc
											 options:kAudioComponentInstantiation_LoadInProcess
								   completionHandler:^(__kindof AVAudioUnit * _Nullable audioUnit, NSError * _Nullable error) {
									   NSLog( @"%@", error );
									   avUnit = audioUnit;
								   }];
	sleep(1);
	
	

	AUAudioUnit *audioUnit = avUnit.AUAudioUnit;
/*
	AUAudioUnit *audioUnit = [[AUAudioUnit alloc] initWithComponentDescription:desc
																	   options:kAudioComponentInstantiation_LoadInProcess
																		 error:&error];
*/
    
    NSLog( @"%@", audioUnit.audioUnitName );
    NSLog( @"%@", audioUnit.audioUnitShortName );
    AUAudioUnitBusArray *busArr = audioUnit.outputBusses;
    NSLog( @"Output buses count %u", busArr.count );
    
    AUAudioUnitBus *outBus = [busArr objectAtIndexedSubscript:0];
    NSLog( @"Chanels count %l", outBus.format.channelCount );
    NSLog( @"Output bus name %@", outBus.name );
    NSLog( @"OutBus sample rate %f", outBus.format.sampleRate );
    
    //dumpStreamFormatDescription( outBus.format.streamDescription );
    
	AudioStreamBasicDescription streamDescription = {0};
	streamDescription.mSampleRate = 8000.0;
	streamDescription.mBitsPerChannel = 32;
	streamDescription.mBytesPerFrame = 4;
	streamDescription.mBytesPerPacket = 4;
	streamDescription.mChannelsPerFrame = 1;
	streamDescription.mFramesPerPacket = 1;
	streamDescription.mFormatID = kAudioFormatLinearPCM;
	
	AVAudioFormat *format = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:0.0 channels:1];
//	format = [[AVAudioFormat alloc] initWithStreamDescription:&streamDescription];
	//format
	//[[audioUnit.outputBusses objectAtIndexedSubscript:0] setFormat:format error:&error];
	//NSLog( @"Set fromat error %@", error );
    [[audioUnit.inputBusses objectAtIndexedSubscript:0] setFormat:format error:&error];
    NSLog( @"Set fromat error %@", error );
	dumpStreamFormatDescription( [audioUnit.inputBusses objectAtIndexedSubscript:0].format.streamDescription );
/*
	AVAudioChannelLayout *chLayout = [[AVAudioChannelLayout alloc] initWithLayoutTag:kAudioChannelLayoutTag_Stereo];
	AVAudioFormat *chFormat = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatFloat32
															   sampleRate:44100.0
															  interleaved:NO
															channelLayout:chLayout];
	dumpStreamFormatDescription( chFormat.streamDescription );

	AVAudioPCMBuffer *thePCMBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:chFormat frameCapacity:1024];
	audioUnit.inputBusses
*/
    //outBus.
	for( AUParameter *param in audioUnit.parameterTree.allParameters )
	{
		NSLog( @"---------------------" );
		dumpAUParameter( param );
	}

	
	//float volume = 0.2f;
    audioUnit.outputProvider = ^AUAudioUnitStatus(AudioUnitRenderActionFlags * _Nonnull actionFlags,
												  const AudioTimeStamp * _Nonnull timestamp,
												  AUAudioFrameCount frameCount,
												  NSInteger inputBusNumber,
												  AudioBufferList * _Nonnull inputData) {
	//	NSLog( @"Sumple time %f", timestamp->mSampleTime );
		if( inputData->mNumberBuffers > 1 )
        {
            render_callback( inputData->mBuffers[0].mData, inputData->mBuffers[0].mDataByteSize,
							 inputData->mBuffers[1].mData, inputData->mBuffers[1].mDataByteSize );
            
        }
		else
		{
			render_callback( inputData->mBuffers[0].mData, inputData->mBuffers[0].mDataByteSize, NULL, 0 );
		}
        return noErr;
    };
	CFStringRef result_str;
	uint32_t volume[20];
	UInt32 result = 0;//sizeof(volume);
	OSStatus os_status = AudioUnitGetProperty(avUnit.audioUnit, kAudioUnitProperty_BusCount,
											0,
										14,
										NULL, &result );
	NSLog( @"Set result %d", os_status );

    [audioUnit allocateRenderResourcesAndReturnError:&error];
	NSLog( @"error %@", error );
    [audioUnit startHardwareAndReturnError:&error];
	NSLog( @"error %@", error );
    sleep( 4 );
    [audioUnit stopHardware];
/*
    //NSLog( @"%d", audioUnit.canPerformOutput);
	for( AUParameter *param in audioUnit.parameterTree.allParameters )
	{
		NSLog( @"---------------------" );
		dumpAUParameter( param );
	}
*/
//	kAudioUnitProperty_MatrixLevels
}

void AudioUnitWorker::init2( )
{
    //AVAudioEngine *engine = [AVAudioEngine new];
    //AVAudioFormat * audioFormat = [engine.outputNode outputFormatForBus:0];
    
}
