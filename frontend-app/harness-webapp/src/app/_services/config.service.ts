import { Injectable } from '@angular/core';
import { environment } from '../../environments/environment';

@Injectable({
  providedIn: 'root'
})
export class ConfigService {
 // apiUrl= environment.defaultApiUrl;
  apiUrl= 'https://backend.slatt.ed.instruqt.io';
  sdkKey= environment.defaultSDKKey;

  constructor() {
   // this.apiUrl = environment.defaultApiUrl;
    this.apiUrl = 'https://backend.slatt.ed.instruqt.io';
  }


  getApiUrl(): string {
    return this.apiUrl;
  }


  getSDKKey(): string{
    return this.sdkKey;
  }




}