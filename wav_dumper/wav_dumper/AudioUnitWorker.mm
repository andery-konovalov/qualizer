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
#include <AVFoundation/AVFoundation.h>

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

	for( NSString *str in param.valueStrings )
	{
		NSLog( @"ValueString %@", str );
	}
}

void AudioUnitWorker::initAudioUnit()
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
    AUAudioUnit *audioUnit = [[AUAudioUnit alloc] initWithComponentDescription:desc options:kAudioComponentInstantiation_LoadInProcess error:&error];
    
    NSLog( @"%@", audioUnit.audioUnitName );
    NSLog( @"%@", audioUnit.audioUnitShortName );
    AUAudioUnitBusArray *busArr = audioUnit.outputBusses;
    NSLog( @"Output buses count %u", busArr.count );
    
    AUAudioUnitBus *outBus = [busArr objectAtIndexedSubscript:0];
    NSLog( @"Output bus name %@", outBus.name );
    outBus.
    //NSLog( @"%d", audioUnit.canPerformOutput);
	for( AUParameter *param in audioUnit.parameterTree.allParameters )
	{
		NSLog( @"---------------------" );
		dumpAUParameter( param );
	}
}

void AudioUnitWorker::init2( )
{
    //AVAudioEngine *engine = [AVAudioEngine new];
    //AVAudioFormat * audioFormat = [engine.outputNode outputFormatForBus:0];
    
}
