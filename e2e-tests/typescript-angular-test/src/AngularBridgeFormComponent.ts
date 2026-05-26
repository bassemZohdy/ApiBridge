import { Component, OnInit, Input, Output, EventEmitter } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { FormGroup } from '@angular/forms';
import { FormlyFieldConfig, FormlyFormOptions } from '@ngx-formly/core';

@Component({
  selector: 'app-bridge-form',
  templateUrl: './bridge-form.component.html',
  styleUrls: ['./bridge-form.component.css']
})
export class BridgeFormComponent implements OnInit {
  @Input() authToken: string = '';
  @Output() onBridgeSubmit = new EventEmitter<Record<string, unknown>>();

  // Mode B: ngx-formly form structures
  form = new FormGroup({});
  model: Record<string, unknown> = {};
  options: FormlyFormOptions = {};
  fields: FormlyFieldConfig[] = [];

  // Dynamic PIM Layout configuration schema
  schema: Record<string, unknown> = {};

  constructor(private http: HttpClient) {}

  ngOnInit(): void {
    this.schema = this.getSchemaDefinition();
    this.initializeFormFields();
  }

  private initializeFormFields(): void {
    this.fields = [
      {
        key: 'email',
        type: 'input',
        templateOptions: {
          label: 'Email',
          required: true,
          placeholder: 'Enter email'
        }
      },
      {
        key: 'companyName',
        type: 'input',
        templateOptions: {
          label: 'Companyname',
          required: true,
          placeholder: 'Enter companyName'
        }
      }
    ];
  }

  /**
   * Safe Dynamic API Forwarder intercepting and routing payloads to the backend integration proxy.
   */
  onSubmit(payload: Record<string, unknown>): void {
    const headersMap: Record<string, string> = {
      'Content-Type': 'application/json'
    };

    if (this.authToken) {
      headersMap['Authorization'] = `Bearer ${this.authToken}`;
    }

    const headers = new HttpHeaders(headersMap);

    // Dispatch endpoint route: /initiate
    const backendUrl = `${this.schema['basePath']}/initiate`;
    this.http.post<Record<string, unknown>>(backendUrl, payload, { headers }).subscribe({
      next: (response: Record<string, unknown>) => {
        this.onBridgeSubmit.emit(response);
      },
      error: (err: unknown) => {
        console.error('ApiBridge submission error:', err);
      }
    });
  }

  private getSchemaDefinition(): Record<string, unknown> {
    return {
      id: "customer-onboarding-bridge",
      basePath: "/api/v1/onboarding",
      securityLevel: "bearer-token"
    };
  }
}
