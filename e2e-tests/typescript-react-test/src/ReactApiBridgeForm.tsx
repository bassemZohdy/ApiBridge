import React, { useRef, useEffect } from 'react';
import axios from 'axios';
import Form from '@rjsf/core';
import validator from '@rjsf/validator-ajv8';
import { RJSFSchema } from '@rjsf/utils';

// Declare custom element for TypeScript validation
declare global {
  namespace JSX {
    interface IntrinsicElements {
      'api-bridge-form': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & {
        ref?: React.RefObject<any>;
        schema?: string;
      }, HTMLElement>;
    }
  }
}

interface ApiBridgeFormProps {
  authToken?: string;
  onBridgeSubmit?: (response: Record<string, unknown>) => void;
}

export const ApiBridgeForm: React.FC<ApiBridgeFormProps> = ({ authToken, onBridgeSubmit }) => {
  
  const schemaDefinition = {
    id: "customer-onboarding-bridge",
    basePath: "/api/v1/onboarding",
    securityLevel: "bearer-token"
  };

  const handleApiSubmit = async (formData: Record<string, unknown>) => {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json'
    };

    if (authToken) {
      headers['Authorization'] = `Bearer ${authToken}`;
    }

    try {
      const backendUrl = `${schemaDefinition.basePath}/initiate`;
      const response = await axios.post<Record<string, unknown>>(backendUrl, formData, { headers });
      if (onBridgeSubmit) {
        onBridgeSubmit(response.data);
      }
    } catch (error) {
      console.error('ApiBridge dynamic form execution failure:', error);
    }
  };

  // Mode B: React JSON Schema Form (RJSF) Engine
  const jsonSchema: RJSFSchema = {
    title: "Customer Onboarding Bridge",
    type: "object",
    required: [
      "email",
      "companyName"
    ],
    properties: {
      "email": {
        type: "string",
        title: "Email"
      },
      "companyName": {
        type: "string",
        title: "Companyname"
      }
    }
  };

  return (
    <div className="api-bridge-container">
      <Form
        schema={jsonSchema}
        validator={validator}
        onSubmit={({ formData }) => handleApiSubmit(formData)}
      />
    </div>
  );
};
