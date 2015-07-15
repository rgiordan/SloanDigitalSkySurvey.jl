module KL


export gen_beta_kl, gen_isobvnormal_improper
export gen_wrappedcauchy_uniform_kl, gen_categorical_kl, gen_gamma_kl
export gen_normal_kl, gen_isobvnormal_kl, gen_diagmvn_mvn_kl


#trigamma(x) = polygamma(1, x)

# Note that KL divergences may be between parameters of two different types,
# e.g. if the prior is a float and the parameter is a dual number.

function gen_beta_kl{NumType <: Number}(alpha2::NumType, beta2::NumType)
    function this_beta_kl{NumType2 <: Number}(alpha1::NumType2, beta1::NumType2)
        alpha_diff = alpha1 - alpha2
        beta_diff = beta1 - beta2
        both_inv_diff = -(alpha_diff + beta_diff)
        di_both1 = digamma(alpha1 + beta1)
        tri_both1 = trigamma(alpha1 + beta1)

        log_term = lgamma(alpha1 + beta1) - lgamma(alpha1) - lgamma(beta1)
        log_term -= lgamma(alpha2 + beta2) - lgamma(alpha2) - lgamma(beta2)
        apart_term = alpha_diff * digamma(alpha1) + beta_diff * digamma(beta1)
        together_term = both_inv_diff * di_both1
        v = log_term + apart_term + together_term

        d_alpha1 = alpha_diff * trigamma(alpha1)
        d_alpha1 += both_inv_diff * tri_both1

        d_beta1 = beta_diff * trigamma(beta1)
        d_beta1 += both_inv_diff * tri_both1

        v, (d_alpha1, d_beta1)
    end
end


function gen_wrappedcauchy_uniform_kl()
    function(scale1)
        v = -log(1 - exp(-2scale1))
        d_scale1 = -2exp(-2scale1) / (1 - exp(-2scale1))
        v, (d_scale1,)
    end
end


function gen_categorical_kl{NumType <: Number}(p2::Vector{NumType})
    function this_categorical_kl{NumType2 <: Number}(p1::Vector{NumType2})
        v = zero(NumType2)
        d_p1 = Array(NumType2, length(p1))

        for i in 1:length(p2)
            log_ratio = log(p1[i]) - log(p2[i])
            v += p1[i] * log_ratio
            d_p1[i] = one(NumType) + log_ratio
        end

        v, (d_p1,)
    end
end


function gen_gamma_kl{NumType <: Number}(k2::NumType, theta2::NumType)
    function(k1, theta1)
        digamma_k1 = digamma(k1)
        theta_ratio = (theta1 - theta2) / theta2
        shape_diff = k1 - k2

        v = shape_diff * digamma_k1
        v += -lgamma(k1) + lgamma(k2)
        v += k2 * (log(theta2) - log(theta1))
        v += k1 * theta_ratio

        d_k1 = shape_diff * trigamma(k1)
        d_k1 += theta_ratio

        d_theta1 = -k2 / theta1
        d_theta1 += k1 / theta2

        v, (d_k1, d_theta1)
    end
end


function gen_normal_kl{NumType <: Number}(mu2::NumType, sigma2Sq::NumType)
    log_sigma2Sq = log(sigma2Sq)
    function(mu1, sigma1Sq)
        diff = mu1 - mu2
        v = .5 * ((log_sigma2Sq - log(sigma1Sq)) + (sigma1Sq + (diff)^2) / sigma2Sq - 1)
        d_mu1 = diff / sigma2Sq
        d_sigma1Sq = 0.5 * (-1. / sigma1Sq + 1 / sigma2Sq)
        v, (d_mu1, d_sigma1Sq)
    end
end


function gen_isobvnormal_kl{NumType <: Number}(mean2::Vector{NumType}, var2::NumType)
    function(mean1, var1)
        diff_sq = (mean1[1] - mean2[1])^2 + (mean1[2] - mean2[2])^2
        v = var1 / var2 + diff_sq / 2var2 - 1 + log(var2 / var1)

        d_mean1 = (mean1 .- mean2) ./ var2
        d_var1 = 1 / var2 - 1 / var1

        v, (d_mean1, d_var1)
    end
end


function gen_diagmvn_mvn_kl{NumType <: Number}(mean2::Vector{NumType}, cov2::Matrix{NumType})
    const precision2 = cov2^-1
    const logdet_cov2 = logdet(cov2)
    const K = length(mean2)

    function this_diagmvn_mvn_kl{NumType2 <: Number}(mean1::Vector{NumType2}, vars1::Vector{NumType2})
        const diag_precision2 = convert(Vector{NumType2}, diag(precision2))
        diff = mean2 - mean1

        v = sum(diag(precision2) .* vars1) - K
        v += (diff' * precision2 * diff)[]
        v += -sum(log(vars1)) + logdet_cov2
        v *= 0.5

        d_mean1 = precision2 * -diff
        d_vars1 = 0.5 * diag_precision2
        d_vars1[:] += -0.5 ./ vars1

        v, (d_mean1, d_vars1)
    end
end


function gen_isobvnormal_flat_kl()
    function(var1)
        v = -(1 + log(2pi) + log(var1))
        d_var1 = -1 / var1
        v, (d_var1,)
    end
end

end

