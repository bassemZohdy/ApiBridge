import { defineComponent, ref, reactive, onMounted, onBeforeUnmount } from 'vue';

export default defineComponent({
  name: 'ApiBridgeForm',
  props: {
    authToken: {
      type: String,
      default: ''
    }
  },
  emits: ['bridgeSubmit'],
  setup(props, { emit }) {
    const schemaDefinition = {
      id: "customer-onboarding-bridge",
      basePath: "/api/v1/onboarding",
      securityLevel: "bearer-token"
    };

    const formData = reactive<Record<string, any>>({
      "email": '',
      "companyName": ''
    });

    const errors = reactive<Record<string, string>>({});

    const validateForm = (): boolean => {
      let isValid = true;
      // Clear errors
      Object.keys(errors).forEach(key => delete errors[key]);

      if (!formData.email) {
        errors.email = 'Email is required';
        isValid = false;
      }
      if (!formData.companyName) {
        errors.companyName = 'Companyname is required';
        isValid = false;
      }
      return isValid;
    };

    const handleApiSubmit = async (payload: Record<string, any>) => {
      const headers: Record<string, string> = {
        'Content-Type': 'application/json'
      };

      if (props.authToken) {
        headers['Authorization'] = `Bearer ${props.authToken}`;
      }

      try {
        const backendUrl = `${schemaDefinition.basePath}/initiate`;
        const response = await fetch(backendUrl, {
          method: 'POST',
          headers,
          body: JSON.stringify(payload)
        });
        const data = await response.json();
        emit('bridgeSubmit', data);
      } catch (error) {
        console.error('Vue ApiBridge dynamic submit error:', error);
      }
    };


    const onSubmit = () => {
      if (validateForm()) {
        handleApiSubmit({ ...formData });
      }
    };

    return {
      formData,
      errors,
      onSubmit,
    };
  }
});
