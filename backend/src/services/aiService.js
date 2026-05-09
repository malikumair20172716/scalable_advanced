/**
 * Azure Cognitive Services (AI) Integration
 * Powers: Auto-tagging, Content Moderation, and Text Analytics
 */

export async function analyzeImage(imageUrl) {
  const endpoint = process.env.CV_ENDPOINT;
  const key = process.env.CV_KEY;

  if (!endpoint || !key) {
    console.warn('AI Warning: CV_ENDPOINT or CV_KEY not configured. Skipping auto-tagging.');
    return [];
  }

  try {
    // Analyze image for tags using Azure Computer Vision API
    const url = `${endpoint.replace(/\/$/, '')}/vision/v3.2/analyze?visualFeatures=Tags`;
    
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Ocp-Apim-Subscription-Key': key,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ url: imageUrl })
    });

    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(`Azure AI Error: ${errorData.message || response.statusText}`);
    }

    const data = await response.json();
    // Return the top 5 most confident tags
    return (data.tags || [])
      .sort((a, b) => b.confidence - a.confidence)
      .slice(0, 5)
      .map(tag => tag.name);
  } catch (error) {
    console.error('AI Error (Analyze):', error.message);
    return [];
  }
}

export async function moderateImage(imageUrl) {
  const endpoint = process.env.CM_ENDPOINT; // Content Moderator
  const key = process.env.CM_KEY;

  if (!endpoint || !key) return { isSafe: true };

  try {
    const url = `${endpoint.replace(/\/$/, '')}/contentmoderator/moderate/v1.0/ProcessImage/Evaluate`;
    
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Ocp-Apim-Subscription-Key': key,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ DataRepresentation: 'URL', Value: imageUrl })
    });

    if (!response.ok) return { isSafe: true };

    const data = await response.json();
    return {
      isSafe: !data.IsImageAdultClassified && !data.IsImageRacyClassified,
      adultScore: data.AdultClassificationScore,
      racyScore: data.RacyClassificationScore
    };
  } catch (error) {
    console.error('AI Error (Moderate):', error.message);
    return { isSafe: true };
  }
}
