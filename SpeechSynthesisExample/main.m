//
//  main.m
//  SpeechSynthesisExample
//
//  Created by Panayotis Matsinopoulos on 18/7/21.
//

#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>
#import <pthread/pthread.h>

#import "AppState.h"
#import "CheckError.h"
#import "NSPrint.h"

void SpeechDone (SpeechChannel chan, SRefCon refCon) {
  AppState *appState = (AppState *)refCon;
  
  pthread_mutex_lock(&(appState->mutex));

  appState->stopSpeaking = true;
  pthread_cond_signal(&(appState->cond));
  
  pthread_mutex_unlock(&(appState->mutex));
}

void InitializeSynchronizationState(AppState *appState) {
  appState->stopSpeaking = false;
  pthread_mutex_init(&(appState->mutex), NULL);
  pthread_cond_init(&(appState->cond), NULL);
}

void SetSpeechCustomData(SpeechChannel channel, AppState *appState) {
  unsigned long appStateAddress = (unsigned long)appState;
  appState->appStateRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberLongType, (const void *)&appStateAddress);
  CheckError(SetSpeechProperty(channel, kSpeechRefConProperty, appState->appStateRef), "Set speech property kSpeechRefConProperty");
}

void DestroySynchronizationState(AppState *appState) {
  pthread_mutex_destroy(&(appState->mutex));
  pthread_cond_destroy(&(appState->cond));
}

void SetSpeechDoneCallBack(SpeechChannel channel, AppState *appState) {
  unsigned long speechDoneAddress = (unsigned long)SpeechDone;
  
  appState->speechDoneRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberLongType, (const void *)&speechDoneAddress);
  
  CheckError(SetSpeechProperty(channel, kSpeechSpeechDoneCallBack, appState->speechDoneRef), "Set speech property kSpeechSpeechDoneCallBack");
  
  InitializeSynchronizationState(appState);
  
  SetSpeechCustomData(channel, appState);
}

void UnsetSpeechDoneCallBack(AppState *appState) {
  CFRelease(appState->speechDoneRef);
  CFRelease(appState->appStateRef);
  
  DestroySynchronizationState(appState);
}

void WaitSpeechToFinish(AppState *appState) {
  pthread_mutex_lock(&(appState->mutex));
  while(!appState->stopSpeaking) {
    pthread_cond_wait(&(appState->cond), &(appState->mutex));
  }
  pthread_mutex_unlock(&(appState->mutex));
}

int main(int argc, const char * argv[]) {
  @autoreleasepool {
    if (argc < 2) {
      NSLog(@"1st argument: You need to give the phrase to be spoken out.\n");
      return 1;
    }
    
    SpeechChannel channel;
    
    NewSpeechChannel(NULL, &channel);

    AppState appState;
    
    SetSpeechDoneCallBack(channel, &appState);
        
    CFStringRef stringToSpeak = CFStringCreateWithCString(kCFAllocatorDefault, argv[1], CFStringGetSystemEncoding());
    
    CheckError(SpeakCFString(channel, stringToSpeak, NULL), "Speak CF String");
    
    WaitSpeechToFinish(&appState);
    
    CheckError(DisposeSpeechChannel(channel), "Dispose speech channel");
        
    UnsetSpeechDoneCallBack(&appState);
    
    CFRelease(stringToSpeak);
        
    NSPrint(@"Bye!\n");
  }
  return 0;
}
