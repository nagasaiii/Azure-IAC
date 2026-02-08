# Cost Analysis & Optimization

## Resource Cost Breakdown

### Azure Cache for Redis (Basic C0)

- **Capacity**: 250 MB
- **Hourly Rate**: $0.020
- **Daily Cost (24hr)**: $0.48
- **Monthly Cost**: ~$14.40

**Optimization Strategy**: Deploy only for testing (15-20 minutes), then destroy immediately.

### Azure Service Bus (Basic Tier)

- **Base Charge**: $0.05 per million operations
- **Typical Test Operations**: < 100
- **Cost**: Negligible (< $0.001)

## Cost Analysis - Actual Deployment Results

This document provides actual cost data from the deployed Azure infrastructure.

### Deployment Details

- **Deployment Date**: February 8, 2026
- **Deployment Duration**: 19 minutes
- **Resources Deployed**: 3 (Resource Group, Redis Cache, Service Bus)

### Resource Cost Breakdown

#### Azure Cache for Redis

- **SKU**: Basic C0 (250MB)
- **Hourly Rate**: $0.020/hour
- **Daily Cost (24 hours)**: $0.48
- **Monthly Cost (730 hours)**: ~$14.60
- **Provisioning Time**: ~15-18 minutes

#### Azure Service Bus

- **SKU**: Basic
- **Base Cost**: $0.05 per million operations
- **Queue Count**: 1 (demo-queue)
- **Estimated Cost for Demo**: < $0.01 (minimal operations)

#### Azure Storage Account (State Backend)

- **SKU**: Standard LRS
- **Usage**: < 1MB (Terraform state file)
- **Monthly Cost**: ~$0.02
- **Transaction Cost**: Negligible (< 1000 operations)

### Total Cost Summary

| Component | Hourly | Daily | Monthly |
| ----------- | -------- | ------- | --------- |
| Redis Cache (Basic C0) | $0.020 | $0.48 | $14.60 |
| Service Bus (Basic) | ~$0.000 | ~$0.00 | ~$0.10 |
| Storage Account | ~$0.000 | ~$0.00 | ~$0.02 |
| **Total** | **$0.020** | **$0.48** | **$14.72** |

### Actual Test Run Cost

For this portfolio demonstration:

- **Deployment Duration**: 19 minutes (~0.32 hours)
- **Cost During Deployment**: $0.020 × 0.32 = **$0.0064**
- **Screenshots/Testing Time**: +10 minutes (~0.17 hours)
- **Total Runtime**: ~30 minutes (~0.5 hours)
- **Estimated Total Cost**: $0.020 × 0.5 = **$0.01**

**Result**: Less than **$0.01 USD** for complete deployment testing! ✅

### Cost Optimization Strategies Applied

1. ✅ **Smallest Tier Selection**: Used Basic C0 for Redis (minimum available)
2. ✅ **Basic Service Bus**: No premium features, pay-per-operation model
3. ✅ **Ephemeral Infrastructure**: Immediate teardown after validation
4. ✅ **Single Region**: East US only (no geo-replication)
5. ✅ **Budget Alerts**: $10 monthly budget with 50%, 75%, 90%, 100% alerts
6. ✅ **Minimal Operations**: No load testing or heavy usage

### Budget Alert Configuration

- **Monthly Budget**: $10.00
- **Current Spend**: < $0.10
- **Remaining Budget**: > $9.90
- **Alert Status**: No alerts triggered ✅

### Cost Comparison

| Scenario | Duration | Cost |
| ---------- | ---------- | ------ |
| This Demo (with immediate destroy) | 30 min | $0.01 |
| Running for 1 day | 24 hours | $0.48 |
| Running for 1 week | 7 days | $3.36 |
| Running for 1 month | 30 days | $14.40 |

**Key Insight**: Immediate teardown reduces costs by **99.9%** compared to leaving resources running for a month.

### Lessons Learned

#### What We Validated

- ✅ Terraform successfully provisions Azure resources
- ✅ Service Principal authentication works correctly
- ✅ Remote state management in Azure Blob Storage functions properly
- ✅ GitHub Actions CI/CD pipeline deploys infrastructure automatically
- ✅ Resource dependencies are handled correctly (Service Bus → Queue)
- ✅ Outputs provide necessary information for verification

#### Cost Management Best Practices Demonstrated

1. **Pre-deployment Planning**: Estimated costs before deploying
2. **Smallest Viable Tier**: Selected minimum SKUs for testing
3. **Monitoring**: Budget alerts configured before deployment
4. **Validation Speed**: Quick screenshot capture and immediate destroy
5. **Documentation**: Real cost data tracked for portfolio evidence

---

**Total Demonstration Cost**: **< $0.01 USD** ✅
