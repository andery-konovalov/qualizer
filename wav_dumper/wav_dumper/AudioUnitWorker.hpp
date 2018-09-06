//
//  AudioUnitWorker.hpp
//  wav_dumper
//
//  Created by Konovalov, Andrii on 21.08.18.
//  Copyright © 2018 Konovalov, Andrii. All rights reserved.
//

#ifndef AudioUnitWorker_hpp
#define AudioUnitWorker_hpp

class AudioUnitWorker
{
public:
    static void initAudioUnit( std::function<void(void *data, uint32_t data_size )> render_callback );
    void init2( );
};
#endif /* AudiUnitWorker_hpp */
