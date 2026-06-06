import * as types from '../../mutation-types';
import InboxesAPI from '../../../api/inboxes';
import AnalyticsHelper from '../../../helper/AnalyticsHelper';
import { ACCOUNT_EVENTS } from '../../../helper/AnalyticsHelper/events';

export const buildInboxData = inboxParams => {
  const formData = new FormData();
  const { channel = {}, ...inboxProperties } = inboxParams;
  Object.keys(inboxProperties).forEach(key => {
    const value = inboxProperties[key];
    // Evita enviar "null" ou "undefined" como string no FormData
    // O backend já tem lógica para tratar string "null", mas é melhor não enviar
    if (value === null || value === undefined) {
      formData.append(key, '');
    } else if (key === 'attendants_queue') {
      formData.append(key, JSON.stringify(value));
    } else {
      formData.append(key, value);
    }
  });
  const { selectedFeatureFlags, ...channelParams } = channel;
  // selectedFeatureFlags needs to be empty when creating a website channel
  if (selectedFeatureFlags) {
    if (selectedFeatureFlags.length) {
      selectedFeatureFlags.forEach(featureFlag => {
        formData.append(`channel[selected_feature_flags][]`, featureFlag);
      });
    } else {
      formData.append('channel[selected_feature_flags][]', '');
    }
  }
  Object.keys(channelParams).forEach(key => {
    const value = channel[key];
    if (value === null || value === undefined) {
      formData.append(`channel[${key}]`, '');
    } else {
      formData.append(`channel[${key}]`, value);
    }
  });
  return formData;
};

const sendAnalyticsEvent = channelType => {
  AnalyticsHelper.track(ACCOUNT_EVENTS.ADDED_AN_INBOX, {
    channelType,
  });
};

export const channelActions = {
  createVoiceChannel: async ({ commit }, params) => {
    try {
      commit(types.default.SET_INBOXES_UI_FLAG, { isCreating: true });
      const response = await InboxesAPI.create({
        name: params.name,
        channel: { ...params.voice, type: 'voice' },
      });
      commit(types.default.ADD_INBOXES, response.data);
      commit(types.default.SET_INBOXES_UI_FLAG, { isCreating: false });
      sendAnalyticsEvent('voice');
      return response.data;
    } catch (error) {
      commit(types.default.SET_INBOXES_UI_FLAG, { isCreating: false });
      throw error;
    }
  },
};
