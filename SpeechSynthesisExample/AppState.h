//
//  AppState.h
//  SpeechSynthesisExample
//
//  Created by Panayotis Matsinopoulos on 19/7/21.
//

#ifndef AppState_h
#define AppState_h

typedef struct _AppState {
  // synchronization related:
  Boolean stopSpeaking;
  pthread_cond_t cond;
  pthread_mutex_t mutex;
  
  // reference to the speech done callback function
  CFNumberRef speechDoneRef;
  
  // reference to the app state variable
  CFNumberRef appStateRef;
} AppState;

#endif /* AppState_h */
